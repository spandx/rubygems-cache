require 'bindata'
require 'digest'
require 'digest/crc'
require 'msgpack'
require 'net/hippie'
require 'nokogiri'
require 'pg'
require 'yaml'
require 'zlib'

require "spandx/rubygems/index"
require "spandx/rubygems/version"

module Spandx
  module Rubygems
    class Error < StandardError; end
  end
end
