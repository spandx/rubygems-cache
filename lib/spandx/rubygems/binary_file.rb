module Spandx
  module Rubygems
    class BinaryFile
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def each(record_type)
        Zlib::GzipReader.open(path) do |io|
          yield record_type.read(io) until io.eof?
        end
      end

      def write
        Zlib::GzipWriter.open(path) do |io|
          yield io
        end
      end
    end
  end
end
