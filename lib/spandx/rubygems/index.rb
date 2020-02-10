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

      def initialize(dir: Dir.pwd)
        @dir = dir

        @backups = Backups.new
        @checkpoints_file = data_file('checkpoints.index', default: [])
        @rubygems_file = data_file('rubygems.index', default: Hash.new { |h, k| h[k] = {} })
      end

      def each
        @rubygems_file.data.each do |key, value|
          yield key, value
        end
      end

      def update!
        @backups.each do |tarfile|
          next if indexed?(tarfile)

          tarfile.each do |row|
            licenses = licenses_for(row['licenses'])
            next if licenses.empty?

            @rubygems_file.data[row['name']][row['version']] = licenses_for(row['licenses'])
          end
          checkpoint!(tarfile)
        end
      end

      private

      def data_file(name, default:)
        DataFile.new(File.expand_path(File.join(dir, name)), default: default)
      end

      def digest_for(string)
        Digest::SHA256.hexdigest(string)
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
        @checkpoints_file.data.include?(tarfile.to_s)
      end

      def checkpoint!(tarfile)
        @rubygems_file.save!
        @checkpoints_file.data.push(tarfile.to_s)
        @checkpoints_file.save!
      end
    end
  end
end
