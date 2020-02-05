# frozen_string_literal: true

=begin
Data structures

hash
* key (full_name) = []

{
  checkpoints: [
    '2019-12-01.tar.gz'
  ],
  items: {
    "rubyzip-0.1.0" => ['MIT']
  }
}


{
  checkpoints: ['2019-12-01.tar.gz'],
  licenses: ['MIT'],
  items: {
    "rubyzip-0.1.0" => [0]
  }
}

=end

module Spandx
  module Rubygems
    class Index
      SQL = <<-DATA
SELECT full_name, licenses
FROM versions
WHERE licenses IS NOT NULL
ORDER BY full_name
      DATA
      attr_reader :path

      def initialize(path: 'rubygems.index')
        @path = File.expand_path(path)
      end

      def update!(base_url: "https://s3-us-west-2.amazonaws.com/rubygems-dumps/")
        each_backup(base_url) do |tarfile|
          next unless tarfile.end_with?('public_postgresql.tar')
          next unless tarfile.start_with?('production')
          next if indexed?(tarfile)

          download(base_url, tarfile) do
            puts ['Inserting', tarfile].inspect
            items = index['items']
            connection.exec(SQL) do |result|
              result.each do |row|
                items[row['full_name']] = YAML.safe_load(row['licenses'])
              end
            end

            checkpoint!(tarfile)
          end
        end
      end

      private

      def indexed?(tarfile)
        index['checkpoints'].include?(tarfile)
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
        xml.search("//Contents/Key").take(1).each do |node|
          yield node.text
        end
      end

      def index
        @index ||= File.exist?(path) ? MessagePack.unpack(IO.binread(path)) : default_layout
      end

      def default_layout
        {
          'checkpoints' => [],
          'items' => {}
        }
      end

      def checkpoint!(tarfile)
        index['checkpoints'].push(tarfile)
        File.open(path, 'w') do |file|
          packer = MessagePack::Packer.new(file)
          packer.write(index)
          packer.flush
        end
        puts ['Checkpoint', tarfile].inspect
      end
    end
  end
end
