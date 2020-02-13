# frozen_string_literal: true

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
      ].freeze
      attr_reader :dir

      def initialize(dir: File.expand_path(File.join(File.dirname(__FILE__), 'index')))
        @dir = dir
        @backups = Backups.new
        @rubygems_file = DataFile.new(File.join(dir, 'rubygems.index'), default: {})
      end

      def each
        @rubygems_file.data.each do |key, value|
          yield key, value
        end
      end

      def update!
        update_expanded_index!
        build_optimized_index!
      end

      private

      def build_optimized_index!
        files = Dir["#{dir}/**/data"]
        count = count_items_from(files)
        puts "Found #{count} items"
        @rubygems_file.batch(size: count) do |io|
          files.each do |data_file_path|
            IO.foreach(data_file_path) do |line|
              json = JSON.parse(line)
              io.write("#{json['name']}-#{json['version']}").write(json['licenses'])
            end
          end
        end
      end

      def count_items_from(filenames)
        filenames.map do |filename|
          %x{wc -l #{filename}}.split.first.to_i
        end.sum
      end

      def update_expanded_index!
        @backups.each do |tarfile|
          next if indexed?(tarfile)

          tarfile.each do |row|
            licenses = licenses_for(row['licenses'])
            next if licenses.empty?

            open_data(row['name']) do |io|
              io.puts(JSON.generate({
                name: row['name'],
                version: row['version'],
                licenses: licenses
              }))
            end
          end
          checkpoint!(tarfile)
        end
      end

      def licenses_for(licenses)
        stripped = licenses.strip!

        return [] if stripped == '--- []'
        return [] if stripped == "--- \n..."

        found = COMMON_LICENSES.find do |x|
          stripped == "---\n- #{x}"
        end
        items = found ? [found] : YAML.safe_load(licenses)
        items.compact
      end

      def indexed?(tarfile)
        checkpoints.include?(tarfile.to_s)
      end

      def checkpoints
        @checkpoints ||=
          begin
            path = 'checkpoints'
            FileUtils.touch(path) unless File.exist?(path)
            IO.readlines(path).map { |x| x.chomp }
          end
      end

      def checkpoint!(tarfile)
        IO.write('checkpoints', "#{tarfile}\n", mode: 'a')
      end

      def digest_for(components)
        Digest::SHA1.hexdigest(Array(components).join('/'))
      end

      def open_data(name, mode: 'a')
        key = digest_for(name)
        FileUtils.mkdir_p(data_dir_for(key))
        File.open(data_file_for(key), mode) do |file|
          yield file
        end
      end

      def data_dir_for(index_key)
        File.join(dir, index_key[0...2])
      end

      def data_file_for(key)
        File.join(data_dir_for(key), 'data')
      end
    end
  end
end
