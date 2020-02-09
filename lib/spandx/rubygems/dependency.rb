# frozen_string_literal: true

module Spandx
  module Rubygems
    class Dependency < BinData::Record
      endian :little
      stringz :identifier
      array :licenses, type: :stringz, initial_length: 1
    end
  end
end
