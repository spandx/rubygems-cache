# frozen_string_literal: true

module Spandx
  module Rubygems
    class Index
      COMMON_LICENSES = ['MIT', 'Apache-2.0', 'GPL-3.0', 'LGPL-3.0', 'BSD', 'BSD-3-Clause', 'WFTPL'].freeze

      def initialize
        @dir = Spandx::Rubygems.root.join('index')
        @rubygems_file = DataFile.new(Spandx::Rubygems.root.join('rubygems.index'), default: {})
      end

      def licenses_for(name:, version:)
        to_h.fetch(index_key_for(name, version), [])
      end

      def each
        to_h.each { |key, value| yield key, value }
      end

      def to_h
        @rubygems_file.data
      end

      def update!
        update_expanded_index!
        sort_index!
        build_optimized_index!
      end

      private

      def index_data_files
        Dir["#{@dir}/**/data"]
      end

      def sort_index!
        index_data_files.each do |file|
          system("awk '!visited[$0]++' #{file} > #{file}1 && mv -f #{file}1 #{file}")
        end
      end

      def build_optimized_index!
        files = index_data_files
        count = count_items_from(files)

        @rubygems_file.batch(size: count) do |io|
          files.each do |data_file_path|
            IO.foreach(data_file_path) do |line|
              json = JSON.parse(line)
              io.write(index_key_for(json['name'], json['version'])).write(json['licenses'])
            end
          end
        end
      end

      def index_key_for(name, version)
        "#{name}-#{version}"
      end

      def count_items_from(filenames)
        filenames.map { |x| `wc -l #{x}`.split.first.to_i }.sum
      end

      def update_expanded_index!
        Backups.new.each do |tarfile|
          next if indexed?(tarfile)

          tarfile.each do |row|
            open_data(row['name']) { |io| io.puts(map_from(row)) }
          end
          checkpoint!(tarfile)
        end
      end

      def map_from(row)
        JSON.generate(name: row['name'], version: row['version'], licenses: extract_licenses_from(row['licenses']))
      end

      def extract_licenses_from(licenses)
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
            path = Spandx::Rubygems.root.join('checkpoints').to_s
            FileUtils.touch(path) unless File.exist?(path)
            IO.readlines(path).map(&:chomp)
          end
      end

      def checkpoint!(tarfile)
        IO.write(Spandx::Rubygems.root.join('checkpoints').to_s, "#{tarfile}\n", mode: 'a')
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
        File.join(@dir, index_key[0...2])
      end

      def data_file_for(key)
        File.join(data_dir_for(key), 'data')
      end
    end
  end
end
