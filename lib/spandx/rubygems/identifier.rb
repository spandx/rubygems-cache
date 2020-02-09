# frozen_string_literal: true

module Spandx
  module Rubygems
    class Identifier < BinData::Array
      endian :little
      uint32 initial_length: 8
    end
  end
end
