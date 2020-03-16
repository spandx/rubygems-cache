# frozen_string_literal: true

RSpec.describe Spandx::Rubygems::Index do
  describe '#licenses_for' do
    [
      { name: 'net-hippie', version: '0.3.2', licenses: ['MIT'] },
      { name: SecureRandom.uuid, version: '0.3.2', licenses: [] },
    ].each do |item|
      specify do
        expect(
          subject.licenses_for(name: item[:name], version: item[:version])
        ).to match_array(item[:licenses])
      end
    end

    Dir['.index/**/rubygems'].sort.each do |filepath|
      context filepath do
        CSV.foreach(filepath) do |csv|
          it "finds `#{csv[0]} #{csv[1]}`" do
            result = subject.licenses_for(name: csv[0], version: csv[1])
            expect(result).to match_array(csv[2].split('-|-'))
          end
        end
      end
    end
  end
end
