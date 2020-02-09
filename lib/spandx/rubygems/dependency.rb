module Spandx
  module Rubygems
    class Dependency < BinData::Record
      endian :little
      identifier :identifier
      array :licenses, type: :identifier, initial_length: 1
    end
  end
end
