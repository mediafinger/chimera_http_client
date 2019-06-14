module ChimeraHttpClient
  class Deserializer
    class << self
      def json_error
        proc do |body|
          JSON.parse(body)
        rescue JSON::ParserError
          { "non_json_body" => body }
        end
      end

      def json_response
        proc do |body|
          JSON.parse(body)
        rescue JSON::ParserError => e
          raise ::ChimeraHttpClient::JsonParserError, "Could not parse body as JSON: #{body}, error: #{e.message}"
        end
      end
    end
  end
end
