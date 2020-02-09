require 'tempfile'

RSpec.describe Spandx::Rubygems::BinaryFile do
  subject { described_class.new(file) }

  let(:file) { Tempfile.new('spandx') }

  describe "#write" do
    def digest(item)
      Digest::SHA256.hexdigest(item)
    end

    it 'can write binary data' do
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

      other = described_class.new(file)
      items = []
      other.each(Spandx::Rubygems::Dependency) do |dependency|
        items << dependency
      end
      expect(items.count).to eql(2)
      expect(items[0].identifier).to eql(digest('spandx-0.1.0'))
      expect(items[0].licenses).to match_array([digest('MIT')])

      expect(items[1].identifier).to eql(digest('spandx-0.1.1'))
      expect(items[1].licenses).to match_array([digest('MIT')])
    end
  end
end
