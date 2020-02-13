# frozen_string_literal: true

RSpec.describe Spandx::Rubygems::Index do
  describe '#licenses_for' do
    [
      { name: 'net-hippie', version: '0.3.2', licenses: ['MIT'] },
    ].each do |item|
      specify do
        expect(
          subject.licenses_for(name: item[:name], version: item[:version])
        ).to match_array(item[:licenses])
      end
    end
  end
end
