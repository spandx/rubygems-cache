require 'spandx/rubygems'
require 'thor'

module Spandx
  module Rubygems
    class CLI < Thor
      desc 'update', 'Updates the rubygems.index'
      def update
        Spandx::Rubygems::Index.new.update!
      end
    end
  end
end
