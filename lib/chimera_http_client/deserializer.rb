# This two JSON deserializers are the default ones
#
# To use custom deserializers, pass them as param to Connection.new or Queue.new:
# `deserializers: { error: your_error_deserializer, response: your_response_deserializer }`
# (you might be able to use the same for both cases)
#
# a Deserializer has to be an object on which the method `call` with the parameter `body` can be called:
# `custom_deserializer.call(body)`
# where `body` is the response body (in the default case a JSON object)
#
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
