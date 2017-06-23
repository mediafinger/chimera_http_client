module HttpClient
  class Request
    TIMEOUT_SECONDS = 5

    def run(url:, method:, body: nil, options: {}, headers: {}, &block)
      request_params = {
        method:          method,
        body:            body,
        params:          options.fetch(:params, {}),
        headers:         headers,
        timeout:         options.fetch(:timeout, TIMEOUT_SECONDS),
        accept_encoding: "gzip",
      }

      # Basic-auth support:
      username = options.fetch(:username, nil)
      password = options.fetch(:password, nil)
      request_params[:userpwd] = "#{username}:#{password}" if username && password

      request = Typhoeus::Request.new(url, request_params)

      result = nil
      request.on_complete do |response|
        result = on_complete_handler(response, &block)
      end

      request.run

      result
    end

    private

    def on_complete_handler(response, &block)
      return Response.new(response) if response.success?

      exception_for(response, &block)
    end

    def exception_for(response, &_block)
      return HttpTimeoutError.new(response) if response.timed_out?

      case response.code.to_i
      when 301, 302, 303, 307
        HttpRedirectionError.new(response)
      when 200..399
        nil
      when 400
        HttpBadRequestError.new(response)
      when 401
        HttpUnauthorizedError.new(response)
      when 403
        HttpForbiddenError.new(response)
      when 404
        HttpNotFoundError.new(response)
      when 405
        HttpMethodNotAllowedError.new(response)
      when 409
        HttpResourceConflictError.new(response)
      when 422
        HttpUnprocessableEntityError.new(response)
      when 400..499
        HttpClientError.new(response)
      when 500..599
        HttpServerError.new(response)
      else # response.code.zero?
        HttpConnectionError.new(response)
      end
    end
  end
end
