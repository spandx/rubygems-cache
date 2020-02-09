module Spandx
  module Rubygems
    class Backup
      SQL = <<-DATA
SELECT full_name, licenses
FROM versions
WHERE licenses IS NOT NULL
ORDER BY full_name
      DATA
      LOAD_SCRIPT = File.expand_path(File.join(File.dirname(__FILE__), '../../../', 'bin/load'))
      attr_reader :uri

      def initialize(uri, db_connection)
        @uri = uri
        @db_connection = db_connection
      end

      def each
        execute(SQL) do |row|
          yield row
        end
      end

      def execute(sql)
        download do
          @db_connection.exec(sql) do |result|
            result.each do |row|
              yield row
            end
          end
        end
      end

      def to_s
        @uri.to_s
      end

      private

      def download
        yield if system(LOAD_SCRIPT, to_s)
      end
    end
  end
end
