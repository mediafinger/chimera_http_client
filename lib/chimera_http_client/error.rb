module ChimeraHttpClient
  class Error < StandardError
    attr_reader :body, :code, :time, :response, :deserializer
    alias message body

    def initialize(response, options = {})
      @body     = response.body
      @code     = response.code
      @time     = response.options&.fetch(:total_time, nil)
      @response = response # contains the request

      @deserializer = options[:error_deserializer]
    end

    def error?
      true
    end

    def parsed_body
      deserializer.call(body)
    end

    def to_s
      error = "#{self.class.name} (#{code}) #{message}, URL: #{url}"

      return "#{error}, Request: #{response.request.inspect}" if log_requests?

      error
    end

    def to_json(_options = {})
      error = {
        code:        code,
        error_class: self.class.name,
        method:      http_method,
        url:         url,
        message:     message,
      }

      return error.merge({ request: response.request.inspect }).to_json if log_requests?

      error.to_json
    end

    private

    def url
      response.request.base_url
    end

    def http_method
      response.request.options[:method]
    end

    def log_requests?
      ENV["CHIMERA_HTTP_CLIENT_LOG_REQUESTS"] == true || ENV["CHIMERA_HTTP_CLIENT_LOG_REQUESTS"] == "true"
    end
  end

  class ParameterMissingError < StandardError; end     # missing parameters
  class JsonParserError < StandardError; end           # body is not parsable json

  class ConnectionError < Error; end           # 0
  class RedirectionError < Error; end          # 301, 302, 303, 307
  class BadRequestError < Error; end           # 400
  class UnauthorizedError < Error; end         # 401
  class ForbiddenError < Error; end            # 403
  class NotFoundError < Error; end             # 404
  class MethodNotAllowedError < Error; end     # 405
  class ResourceConflictError < Error; end     # 409
  class UnprocessableEntityError < Error; end  # 422
  class ClientError < Error; end               # 400..499
  class ServerError < Error; end               # 500..599
  class TimeoutError < Error; end              # timeout
end
