# frozen_string_literal: true

require 'tempfile'

RSpec.describe Spandx::Rubygems::BinaryFile do
  subject { described_class.new(file) }

  let(:file) { Tempfile.new('spandx') }

  describe '#write' do
    def digest(item)
      Digest::SHA256.hexdigest(item)
    end

    before do
      subject.write do |io|
        Spandx::Rubygems::Dependency.new(
          identifier: digest('spandx-0.1.0'),
          licenses: [digest('MIT')]
        ).write(io)
        Spandx::Rubygems::Dependency.new(
          identifier: digest('spandx-0.1.1'),
          licenses: [digest('MIT')]
        ).write(io)
      end
    end

    let(:results) do
      items = []
      described_class.new(file).each(Spandx::Rubygems::Dependency) do |dependency|
        items << dependency
      end
      items
    end

    specify { expect(results.count).to be(2) }
    specify { expect(results[0].identifier).to eql(digest('spandx-0.1.0')) }
    specify { expect(results[0].licenses).to match_array([digest('MIT')]) }

    specify { expect(results[1].identifier).to eql(digest('spandx-0.1.1')) }
    specify { expect(results[1].licenses).to match_array([digest('MIT')]) }
  end
end
