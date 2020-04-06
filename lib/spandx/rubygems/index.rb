# frozen_string_literal: true

module Spandx
  module Rubygems
    class Index
      COMMON_LICENSES = ['MIT', 'Apache-2.0', 'GPL-3.0', 'LGPL-3.0', 'BSD', 'BSD-3-Clause', 'WFTPL'].freeze
      CORRECTIONS = {
        'AGPLv3' => 'AGPL-3.0',
        'APACHE-2' => 'Apache-2.0',
        'APLv2' => 'Apache-2.0',
        'Apache 2' => 'Apache-2.0',
        'Apache 2.0' => 'Apache-2.0',
        'Apache License (2.0)' => 'Apache-2.0',
        'Apache License 2.0' => 'Apache-2.0',
        'Apache License v2.0' => 'Apache-2.0',
        'Apache License Version 2.0' => 'Apache-2.0',
        'MPLv2' => 'MPL-2.0',
        'BSD 2-clause' => 'BSD-2-Clause',
        'GNU GPL v3' => 'GPL-3.0-only',
        'GNU LESSER GENERAL PUBLIC LICENSE' => 'LGPL-3.0',
        'GPL-2' => 'GPL-2.0',
        'GPL3' => 'GPL-3.0-only',
        'LGPL-3' => 'LGPL-3.0',
        'LGPLv3' => 'LGPL-3.0-only',
        'GPL-3+' => 'GPL-3.0-or-later',
        'ASL2' => 'Apache-2.0',
        'GPLv3' => 'GPL-3.0-only',
        '2-clause BSD-style license' => 'BSD-2-Clause',
        'GNU General Public License version 3.0 (GPL-3.0)' => 'GPL-3.0',
      }

      def initialize
        @dir = Spandx::Rubygems.root.join('../../../.index')
      end

      def licenses_for(name:, version:)
        search_key = [name, version].join(',')
        open_data(name, mode: 'r') do |io|
          found = io.readlines.bsearch { |x| search_key <=> [x[0], x[1]].join(',') }
          found ? found[2].split('-|-') : []
        end
      end

      def each
        Dir[@dir.join('**/rubygems')].each do |path|
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
        Dir["#{@dir}/**/rubygems"]
      end

      def sort_index!
        [checkpoints_path] + index_data_files.each do |file|
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
        backups = Backups.new
        backups.to_a.reverse.take(1).each do |tarfile|
          next if indexed?(tarfile)

          tarfile.each do |row|
            name = row['full_name'].gsub(/\n/, '').gsub("-#{row['version']}", '')
            open_data(name) do |io|
              io << [name, row['version'], extract_licenses_from(row['licenses']).join('-|-')]
            end
          end
          checkpoint!(tarfile)
        end
      end

      def extract_licenses_from(licenses)
        stripped = licenses.strip!
        return [] if stripped == '--- []'
        return [] if stripped == "--- \n..."

        items = YAML.safe_load(licenses)
        return [] if items.nil? || items.empty?

        items.compact.map { |x| CORRECTIONS.fetch(x, x).gsub(/\n/, '') }
      end

      def indexed?(tarfile)
        checkpoints.include?(tarfile.to_s)
      end

      def checkpoints_path
        @checkpoints_path ||= File.join(@dir, 'rubygems.checkpoints')
      end

      def checkpoints
        @checkpoints ||=
          begin
            FileUtils.touch(checkpoints_path) unless File.exist?(checkpoints_path)
            IO.readlines(checkpoints_path).map(&:chomp)
          end
      end

      def checkpoint!(tarfile)
        IO.write(checkpoints_path, "#{tarfile}\n", mode: 'a')
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
        File.join(data_dir_for(key), 'rubygems')
      end
    end
  end
end
