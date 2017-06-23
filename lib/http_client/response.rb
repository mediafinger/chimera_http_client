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
    end

    def error?
      false
    end
  end
end
