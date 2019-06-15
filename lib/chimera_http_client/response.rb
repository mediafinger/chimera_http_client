module ChimeraHttpClient
  class Response
    attr_reader :body, :code, :time, :response, :deserializer

    def initialize(response, options = {})
      @body     = response.body
      @code     = response.code
      @time     = response.total_time
      @response = response # contains the request

      @deserializer = options[:deserializer][:response]
    end

    def parsed_body
      deserializer.call(body)
    end

    def error?
      false
    end
  end
end
