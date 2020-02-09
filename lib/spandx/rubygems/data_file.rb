
module Spandx
  module Rubygems
    class DataFile
      attr_reader :path, :data

      def initialize(path, default: {})
        @path = path
        @data = read(default: default)
      end

      def size
        File.size(path)
      end

      def flush!
        write(data)
      end

      private

      def read(default: nil)
        return default unless File.exist?(path)
        return default if File.empty?(path)

        MessagePack.unpack(Zlib::GzipReader.open(path) { |io| io.read })
      end

      def write(data)
        Zlib::GzipWriter.open(path) do |io|
          packer = MessagePack::Packer.new(io)
          packer.write(data)
          packer.flush
        end
      end
    end
  end
end
