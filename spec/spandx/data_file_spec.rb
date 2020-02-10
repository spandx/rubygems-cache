# frozen_string_literal: true

require 'tempfile'

RSpec.describe Spandx::Rubygems::DataFile do
  subject { described_class.new(file) }

  let(:file) { Tempfile.new('spandx') }

  describe '#save!' do
    it 'can read what was written' do
      subject.data[:hello] = 'world'
      subject.save!

      other = described_class.new(file)
      expect(other.data).to eql('hello' => 'world')
    end

    # id: 32 bytes
    # licenses: [1] => 32 bytes
    # 64 bytes / entry
    context 'when writing a large amount of data' do
      before do
        163_840.times do |n|
          subject.data["spandx-0.1.#{n}"] = ['MIT']
        end
        subject.save!
      end

      specify { expect(subject.data).to eql(described_class.new(file).data) }
      specify { expect(subject.size).to be < 10_485_760 }
    end
  end

  describe '#size' do
    it 'can provide the size of the file' do
      subject.data['spandx'] = ['MIT']
      subject.save!
      expect(subject.size).to eql(File.size(subject.path))
    end
  end
end