# frozen_string_literal: true

module Spandx
  module Rubygems
    class Backups
      attr_reader :base_url

      def initialize(base_url: 'https://s3-us-west-2.amazonaws.com/rubygems-dumps/')
        @base_url = base_url
        @http = Net::Hippie::Client.new
        @db_connection = PG.connect(host: File.expand_path('tmp/sockets'), dbname: 'postgres')
      end

      def each
        response = @http.get(base_url)
        to_xml(response.body).search('//Contents/Key').reverse.each do |node|
          next unless valid?(node.text)

          yield Backup.new(URI.join(base_url, node.text), @db_connection)
        end
      end

      private

      def to_xml(raw_xml)
        Nokogiri::XML(raw_xml).tap(&:remove_namespaces!)
      end

      def valid?(text)
        text.end_with?('public_postgresql.tar') &&
          text.start_with?('production')
      end
    end
  end
end
