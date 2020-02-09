
module Spandx
  module Rubygems
    class DataFile
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def size
        File.size(path)
      end

      def read(default: nil)
        return default unless File.exist?(path)

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
