
module Spandx
  module Rubygems
    class Backups
      attr_reader :base_url

      def initialize(base_url: "https://s3-us-west-2.amazonaws.com/rubygems-dumps/")
        @base_url = base_url
      end

      def each
        response = Net::Hippie::Client.new.get(base_url)
        xml = Nokogiri::XML(response.body).tap(&:remove_namespaces!)
        xml.search("//Contents/Key").reverse.each do |node|
          next unless node.text.end_with?('public_postgresql.tar')
          next unless node.text.start_with?('production')
          yield URI.join(base_url, node.text)
        end
      end
    end
  end
end
