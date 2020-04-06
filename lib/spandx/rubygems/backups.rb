# frozen_string_literal: true

module Spandx
  module Rubygems
    class Backups
      include Enumerable

      attr_reader :base_url

      def initialize(base_url: 'https://s3-us-west-2.amazonaws.com/rubygems-dumps/')
        @base_url = base_url
        @http = Net::Hippie::Client.new
      end

      def each
        response = @http.get(base_url)
        to_xml(response.body).search('//Contents/Key').each do |node|
          next unless valid?(node.text)

          yield Backup.new(URI.join(base_url, node.text), db_connection)
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

      def db_connection
        @db_connection ||=
          begin
            require 'pg'
            PG.connect(host: pg_host, dbname: pg_dbname, user: pg_user, port: pg_port)
          end
      end

      def pg_host
        ENV.fetch('PGHOST', File.expand_path('tmp/sockets'))
      end

      def pg_user
        ENV['PGUSER']
      end

      def pg_dbname
        ENV.fetch('PGDBNAME', 'postgres')
      end

      def pg_port
        ENV['PGPORT']
      end
    end
  end
end
