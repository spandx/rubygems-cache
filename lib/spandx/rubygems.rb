# frozen_string_literal: true

require 'csv'
require 'digest'
require 'net/hippie'
require 'nokogiri'
require 'pathname'
require 'spandx'
require 'yaml'
require 'zlib'

require 'spandx/rubygems/backup'
require 'spandx/rubygems/backups'
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
