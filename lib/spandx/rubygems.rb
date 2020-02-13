# frozen_string_literal: true

require 'digest'
require 'msgpack'
require 'net/hippie'
require 'nokogiri'
require 'yaml'
require 'zlib'

require 'spandx/rubygems/backup'
require 'spandx/rubygems/backups'
require 'spandx/rubygems/data_file'
require 'spandx/rubygems/index'
require 'spandx/rubygems/version'

module Spandx
  module Rubygems
    class Error < StandardError; end

    class << self
      def root
        Pathname.new(File.dirname(__FILE__)).join('rubygems')
      end
    end
  end
end
