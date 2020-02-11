# frozen_string_literal: true

require 'spandx/rubygems'
require 'thor'

module Spandx
  module Rubygems
    class CLI < Thor
      desc 'list', 'List the rubygems.index'
      def list
        index.each do |name, licenses|
          next if name.start_with?('   x-')
          puts [name, licenses].inspect
        end
      end

      desc 'update', 'Updates the rubygems.index'
      def update
        index.update!
      end

      private

      def index
        Spandx::Rubygems::Index.new
      end
    end
  end
end
