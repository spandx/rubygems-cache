# frozen_string_literal: true

RSpec.describe Spandx::Rubygems do
  specify { expect(Spandx::Rubygems::VERSION).not_to be_nil }
end
