# frozen_string_literal: true

module Spandx
  module Rubygems
    class Index
      COMMON_LICENSES = ['MIT', 'Apache-2.0', 'GPL-3.0', 'LGPL-3.0', 'BSD', 'BSD-3-Clause', 'WFTPL'].freeze
      CORRECTIONS = {
        '2-clause BSD-style license' => 'BSD-2-Clause',
        'AGPLv3' => 'AGPL-3.0',
        'Apache 2.0' => 'Apache-2.0',
        'APACHE-2' => 'Apache-2.0',
        'Apache 2' => 'Apache-2.0',
        'Apache License (2.0)' => 'Apache-2.0',
        'Apache License 2.0' => 'Apache-2.0',
        'Apache License v2.0' => 'Apache-2.0',
        'Apache License Version 2.0' => 'Apache-2.0',
        'Apache License, Version 2.0' => 'Apache-2.0',
        'APLv2' => 'Apache-2.0',
        'ASL2' => 'Apache-2.0',
        'BSD 2-clause' => 'BSD-2-Clause',
        'GNU General Public License version 3.0 (GPL-3.0)' => 'GPL-3.0',
        'GNU GPL v3' => 'GPL-3.0-only',
        'GNU LESSER GENERAL PUBLIC LICENSE' => 'LGPL-3.0',
        'GPL-2' => 'GPL-2.0',
        'GPL3' => 'GPL-3.0-only',
        'GPL-3+' => 'GPL-3.0-or-later',
        'GPLv3' => 'GPL-3.0-only',
        'LGPL-3' => 'LGPL-3.0',
        'LGPLv3' => 'LGPL-3.0-only',
        'MPLv2' => 'MPL-2.0',
      }.freeze

      attr_reader :cache

      def initialize
        @cache = ::Spandx::Core::Cache.new('rubygems', root: Spandx::Rubygems.root.join('../../../.index'))
      end

      def licenses_for(name:, version:)
        cache.licenses_for(name, version)
      end

      def each
        cache.each { |item| yield item }
      end

      def update!
        update_expanded_index!
        cache.rebuild_index
      end

      private

      def update_expanded_index!
        Backups.latest do |backup|
          backup.each do |row|
            name = row['full_name'].gsub(/\n/, '').gsub("-#{row['version']}", '')
            cache.insert(name, row['version'], extract_licenses_from(row['licenses']))
          end
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
    end
  end
end
