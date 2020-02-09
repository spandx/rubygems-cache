# frozen_string_literal: true

require 'tempfile'

RSpec.describe Spandx::Rubygems::DataFile do
  subject { described_class.new(file) }

  let(:file) { Tempfile.new('spandx') }

  describe "#write" do
    it 'can read what was written' do
      subject.write({ hello: 'world' })
      expect(subject.read).to eql({ 'hello' => 'world' })
    end

    it 'can write a large amount of data' do
      items = {}
      163_840.times do |n|
        items["spandx-0.1.#{n}"] = ['MIT']
      end
      subject.write(items)

      # id: 32 bytes
      # licenses: [1] => 32 bytes
      # 64 bytes / entry

      expect(items).to eql(subject.read)
      puts subject.size.inspect
      expect(subject.size).to be < 10_485_760
    end
  end

  describe "#size" do
    it 'can provide the size of the file' do
      subject.write({ 'spandx' =>  ['MIT'] })
      expect(subject.size).to eql(File.size(subject.path))
    end
  end
end
