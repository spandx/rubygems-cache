# frozen_string_literal: true

=begin
rubygems.checkpoints
[
  '2019-12-01.tar.gz'
]

licenses.index
{
  crc32("SPDX Expression") => "SPDX Expression"
}

rubygems.index
- crc32("rubyzip-0.1.0") | crc32("SPDX Expression")
=end

module Spandx
  module Rubygems
    class Dependency < BinData::Record
      endian :little
      uint32 :id
      array :licenses, type: :uint32, initial_length: 1
    end

    class Index
      COMMON_LICENSES = [
        'MIT',
        'Apache-2.0',
        'GPL-3.0',
        'LGPL-3.0',
        'BSD',
        'BSD-3-Clause',
        'WFTPL'
      ]
      SQL = <<-DATA
SELECT full_name, licenses
FROM versions
WHERE licenses IS NOT NULL
ORDER BY full_name
      DATA
      attr_reader :checkpoints_path, :licenses_path, :rubygems_path

      def initialize(dir: Dir.pwd)
        @checkpoints_path = File.expand_path(File.join(dir, 'checkpoints.index'))
        @licenses_path = File.expand_path(File.join(dir, 'licenses.index'))
        @rubygems_path = File.expand_path(File.join(dir, 'rubygems.index'))
      end

      def each
        Zlib::GzipReader.open(rubygems_path) do |io|
          until io.eof?
            dependency = Dependency.read(io)
            yield dependency.id, dependency.licenses.map { |x| licenses_index[x] }
          end
        end
      end

      def update!(base_url: "https://s3-us-west-2.amazonaws.com/rubygems-dumps/")
        dependency = Dependency.new

        each_backup(base_url) do |tarfile|
          next if indexed?(tarfile)

          download(base_url, tarfile) do
            Zlib::GzipWriter.open(rubygems_path) do |io|
              puts ['Inserting', tarfile].inspect
              connection.exec(SQL) do |result|
                result.each_with_index do |row, index|
                  key = key_for(row['full_name'])
                  licenses = licenses_for(row['licenses'])

                  puts [key, licenses].inspect
                  next if licenses.empty?
                  dependency.clear
                  dependency.assign(name: key, licenses: licenses)
                  dependency.write(io)
                end
              end

              io.flush
              checkpoint!(tarfile)
            end
          end
        end
      end

      private

      def key_for(string)
        Digest::CRC32.digest(string).unpack('V*')[0]
      end

      def licenses_for(licenses)
        stripped = licenses.strip!

        return [] if stripped == "--- []"
        return [] if stripped == "--- \n..."
        found = COMMON_LICENSES.find do |x|
          stripped == "---\n- #{x}"
        end
        items = found ? [found] : YAML.safe_load(licenses)

        items.map do |item|
          key = key_for(item)
          licenses_index[key] = item
          key
        end
      end

      def indexed?(tarfile)
        checkpoints_index.include?(tarfile)
      end

      def connection
        @connection ||= PG.connect(host: File.expand_path('tmp/sockets'), dbname: 'postgres')
      end

      def download(base_url, tarfile)
        load_script = File.expand_path(File.join(File.dirname(__FILE__), '../../../', 'bin/load'))

        uri = URI.join(base_url, tarfile).to_s
        if system(load_script, uri)
          yield
        end
      end

      def each_backup(base_url)
        response = Net::Hippie::Client.new.get(base_url)
        xml = Nokogiri::XML(response.body).tap(&:remove_namespaces!)
        xml.search("//Contents/Key").reverse.each do |node|
          next unless node.text.end_with?('public_postgresql.tar')
          next unless node.text.start_with?('production')
          yield node.text
        end
      end

      def checkpoints_index
        @checkpoints_index ||= read_index(checkpoints_path, [])
      end

      def licenses_index
        @index ||= read_index(licenses_path, {})
      end

      def read_index(path, default)
        return default unless File.exist?(path)

        MessagePack.unpack(Zlib::GzipReader.open(path) { |gz| gz.read })
      end

      def checkpoint!(tarfile)
        checkpoints_index.push(tarfile)
        flush!(licenses_path, licenses_index)
        flush!(checkpoints_path, checkpoints_index)
      end

      def flush!(path, index)
        Zlib::GzipWriter.open(path) do |io|
          packer = MessagePack::Packer.new(io)
          packer.write(index)
          packer.flush
        end
      end
    end
  end
end
