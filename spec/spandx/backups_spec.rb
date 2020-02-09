RSpec.describe Spandx::Rubygems::Backups do
  describe "#each" do
    let(:results) do
      items = []
      VCR.use_cassette('rubygems-dumps') do
        subject.each do |x|
          items << x.to_s
        end
      end
      items
    end

    specify { expect(results.count).to eql(121) }
    specify { expect(results.all? { |x| x.end_with?('public_postgresql.tar') }).to be(true) }
    specify { expect(results.none? { |x| x.include?('staging') }).to be(true) }
    specify { expect(results.all? { |x| x.start_with?(subject.base_url) }).to be(true) }
    specify { expect(results.last).to eql("https://s3-us-west-2.amazonaws.com/rubygems-dumps/production/public_postgresql/2019.10.12.13.10.08/public_postgresql.tar") }
  end
end
