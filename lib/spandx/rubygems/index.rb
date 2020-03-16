# frozen_string_literal: true

module Spandx
  module Rubygems
    class Index
      COMMON_LICENSES = ['MIT', 'Apache-2.0', 'GPL-3.0', 'LGPL-3.0', 'BSD', 'BSD-3-Clause', 'WFTPL'].freeze

      def initialize
        @dir = Spandx::Rubygems.root.join('index')
      end

      def licenses_for(name:, version:)
        search_key = [name, version].join(',')
        open_data(name, mode: 'r') do |io|
          found = io.readlines.bsearch { |x| search_key <=> [x[0], x[1]].join(',') }
          found ? found[2].split('-|-') : []
        end
      end

      def each
        Dir[@dir.join('**/data')].each do |path|
          CSV.open(path, 'r') do |io|
            yield io.readline until io.eof?
          end
        end
      end

      def update!
        update_expanded_index!
        sort_index!
      end

      private

      def index_data_files
        Dir["#{@dir}/**/data"]
      end

      def sort_index!
        [Spandx::Rubygems.root.join('checkpoints').to_s] + index_data_files.each do |file|
          IO.write(file, IO.readlines(file).sort.uniq.join)
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
            open_data(row['name']) do |io|
              io << [row['name'], row['version'], extract_licenses_from(row['licenses']).join('-|-')]
            end
          end
          checkpoint!(tarfile)
        end
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

      def open_data(name, mode: 'ab')
        file = data_file_for(digest_for(name))
        FileUtils.mkdir_p(File.dirname(file))
        CSV.open(file, mode) do |csv|
          yield csv
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
