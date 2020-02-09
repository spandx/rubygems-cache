# frozen_string_literal: true

module Spandx
  module Rubygems
    class DataFile
      attr_reader :path, :data

      def initialize(path, default: {})
        puts path.inspect
        @path = path
        @data = read(default: default)
      end

      def size
        File.size(path)
      end

      def save!
        write(data)
      end

      private

      def read(default: nil)
        return default unless File.exist?(path)
        return default if File.empty?(path)

        MessagePack.unpack(Zlib::GzipReader.open(path, &:read))
      end

      def write(data)
        FileUtils.mkdir_p(File.dirname(path))
        puts "Saving #{path}"
        Zlib::GzipWriter.open(path) do |io|
          packer = MessagePack::Packer.new(io)
          packer.write(data)
          packer.flush
        end
      end
    end
  end
end
