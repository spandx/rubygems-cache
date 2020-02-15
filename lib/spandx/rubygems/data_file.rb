# frozen_string_literal: true

module Spandx
  module Rubygems
    class DataFile
      attr_reader :path

      def initialize(path, default: {})
        @path = path
        @default = default
      end

      def data
        @data ||= read(default: @default)
      end

      def size
        File.size(path)
      end

      def batch(size:)
        # Zlib::GzipWriter.open(path) do |io|
        # packer = MessagePack::Packer.new(io)
        # packer.write_map_header(size)
        # yield packer
        # packer.flush
        # end
        File.open(path, 'wb') do |io|
          packer = MessagePack::Packer.new(io)
          packer.write_map_header(size)
          yield packer
          packer.flush
        end
      end

      def save!
        write(data)
      end

      private

      def read(default: nil)
        return default unless File.exist?(path)
        return default if File.empty?(path)

        # Zlib::GzipReader.open(path) do |io|
        # MessagePack.unpack(io.read)
        # end

        File.open(path, 'rb') do |io|
          MessagePack.unpack(io.read)
        end
      end

      def write(data)
        FileUtils.mkdir_p(File.dirname(path))
        # Zlib::GzipWriter.open(path) do |io|
        # packer = MessagePack::Packer.new(io)
        # packer.write(data)
        # packer.flush
        # end
        File.open(path, 'wb') do |io|
          packer = MessagePack::Packer.new(io)
          packer.write(data)
          packer.flush
        end
      end
    end
  end
end
