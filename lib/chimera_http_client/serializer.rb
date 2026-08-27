# The default JSON serializer for request bodies.
#
# To use a custom serializer, pass it as a param to Connection.new or Queue.new:
# `serializer: your_serializer`
# or override it for a single request: `connection.post(endpoint, body: {...}, serializer: your_serializer)`
#
# A Serializer has to be an object on which the method `call` with the parameter `body` can be called:
# `custom_serializer.call(body)`
# It is only ever invoked for a Hash or Array body - anything else (e.g. an already-serialized
# String) is passed to the request unchanged. It normally returns a String, but may also return
# a Hash - Typhoeus/Ethon will then form-encode it natively (application/x-www-form-urlencoded,
# or multipart if a value looks file-shaped), so an identity serializer (`->(body) { body }`) is
# a valid way to opt into that instead of JSON.
#
module ChimeraHttpClient
  class Serializer
    class << self
      def json
        proc { |body| body.to_json }
      end
    end
  end
end
