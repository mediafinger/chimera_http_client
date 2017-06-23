module HttpClient
  class Response
    attr_reader :body, :code, :time, :response

    def initialize(response)
      @body     = response.body
      @code     = response.code
      @time     = response.total_time
      @response = response # contains the request
    end

    def parsed_body
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise HttpClient::JsonParserError, "Could not parse body as JSON: #{body}, error: #{e.message}"
    end

    def error?
      false
    end
  end
end
