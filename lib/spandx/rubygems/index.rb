# frozen_string_literal: true

=begin
rubygems.checkpoints
[
  '2019-12-01.tar.gz'
]

licenses.index
{
  sha256("SPDX Expression") => "SPDX Expression"
}

rubygems.index
- sha256("rubyzip-0.1.0") | sha256("SPDX Expression")
=end

module Spandx
  module Rubygems
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
      attr_reader :rubygems_path

      def initialize(dir: Dir.pwd)
        @rubygems_path = File.expand_path(File.join(dir, 'rubygems.index'))

        @backups = Backups.new
        @licenses_file = DataFile.new(File.expand_path(File.join(dir, 'licenses.index')), default: {})
        @checkpoints_file = DataFile.new(File.expand_path(File.join(dir, 'checkpoints.index')), default: [])
      end

      def each
        Zlib::GzipReader.open(rubygems_path) do |io|
          until io.eof?
            dependency = Dependency.read(io)
            yield to_hex(dependency.identifier), dependency.licenses.map { |x| to_hex(@licenses_file.data[x]) }
          end
        end
      end

      def update!
        @backups.each do |tarfile|
          next if indexed?(tarfile)

          Zlib::GzipWriter.open(rubygems_path) do |io|
            tarfile.each do |row|
              map_from(row)&.write(io)
            end
            io.flush
            checkpoint!(tarfile)
          end
        end
      end

      private

      def map_from(row)
        licenses = licenses_for(row['licenses'])
        return if licenses.empty?

        Dependency.new(
          identifier: key_for(row['full_name']),
          licenses: licenses
        )
      end

      def to_hex(item)
        item
      end

      def key_for(string)
        Digest::SHA256.digest(string).unpack('V*')
      end

      def licenses_for(licenses)
        stripped = licenses.strip!

        return [] if stripped == "--- []"
        return [] if stripped == "--- \n..."
        found = COMMON_LICENSES.find do |x|
          stripped == "---\n- #{x}"
        end
        items = found ? [found] : YAML.safe_load(licenses)

        items.compact.map do |item|
          key = key_for(item)
          @licenses_file.data[key] = item
          key
        end
      end

      def indexed?(tarfile)
        @checkpoints_file.data.include?(tarfile.to_s)
      end

      def checkpoint!(tarfile)
        @licenses_file.save!
        @checkpoints_file.data.push(tarfile.to_s)
        @checkpoints_file.save!
      end
    end
  end
end
