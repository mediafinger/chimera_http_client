module ChimeraHttpClient
  class Request
    TIMEOUT_SECONDS = 3

    # Only idempotent methods are retried automatically, regardless of the configured retries count
    RETRYABLE_METHODS = %i(get put delete head).freeze

    # Only network failures and 5xx are retried - 4xx client errors can't be fixed by retrying
    RETRYABLE_ERRORS = [ConnectionError, TimeoutError, ServerError].freeze

    RETRY_BACKOFF_MULTIPLIER = 2

    attr_reader :request, :result

    def initialize(options = {})
      @options = options
      @hydra = options[:hydra]
      @attempt = 0
    end

    def run(url:, method:, body: nil, options: {}, headers: {})
      create(url: url, method: method, body: body, options: options, headers: headers)

      @request.run

      attempt = 0
      while retryable?(method, @result, options, attempt)
        attempt += 1
        sleep(delay_for(attempt, options))

        create(url: url, method: method, body: body, options: options, headers: headers)
        @request.run
      end

      @result
    end

    def create(url:, method:, body: nil, options: {}, headers: {})
      request_params = {
        method:          method,
        body:            body,
        params:          options[:params] || {},
        headers:         headers,
        timeout:         options[:timeout] || TIMEOUT_SECONDS,
        accept_encoding: "gzip",
        cache:           options[:cache],
        verbose:         options[:verbose],
      }

      # Basic-auth support:
      username = options.fetch(:username, nil)
      password = options.fetch(:password, nil)
      request_params[:userpwd] = "#{username}:#{password}" if username && password

      @request = Typhoeus::Request.new(url, request_params)

      @result = nil
      @request.on_complete do |response|
        runtime = response.total_time&.round(3)

        @options[:monitor]&.call(
          {
            url: url, method: method, status: response.code, runtime: runtime,
            completed_at: Time.now.utc.iso8601(3), context: options[:monitoring_context]
          }
        )

        @options[:logger]&.info(
          {
            message: "Completed Chimera HTTP Request",
            method: method.upcase,
            url: url,
            code: response.code,
            runtime: runtime,
            user_agent: headers["User-Agent"],
          }
        )

        result = on_complete_handler(response)

        # Used for queued requests (Queue): retries are re-queued onto the same Hydra from
        # inside this callback, per Typhoeus::Hydra::Queueable#queue ("can even be done while
        # the hydra is running"). Connection-built requests never have a @hydra, so this branch
        # never triggers for them - their retries are handled by the loop in #run instead.
        if @hydra && retryable?(method, result, options, @attempt)
          @attempt += 1
          sleep(delay_for(@attempt, options))

          create(url: url, method: method, body: body, options: options, headers: headers)
          @hydra.queue(@request)
        else
          @result = result
        end
      end

      @options[:logger]&.info(
        {
          message: "Starting Chimera HTTP Request",
          method: method.upcase,
          url: url,
          code: nil,
          runtime: 0,
          user_agent: headers["User-Agent"],
        }
      )

      self
    end

    private

    def retryable?(method, result, options, attempt)
      result.error? &&
        RETRYABLE_METHODS.include?(method) &&
        RETRYABLE_ERRORS.any? { |klass| result.is_a?(klass) } &&
        attempt < options[:retries].to_i
    end

    # Delay before retry attempt n (1-indexed): retry_delay * RETRY_BACKOFF_MULTIPLIER**(n - 1)
    def delay_for(attempt, options)
      options[:retry_delay].to_f * (RETRY_BACKOFF_MULTIPLIER**(attempt - 1))
    end

    def on_complete_handler(response)
      return Response.new(response, @options) if response.success?

      exception_for(response)
    end

    def exception_for(response)
      return TimeoutError.new(response, @options) if response.timed_out?

      case response.code.to_i
      when 301, 302, 303, 307
        RedirectionError.new(response, @options) # TODO: throw error conditionally
      when 200..399
        nil # TODO: decide to either raise error or return a Response
      when 400
        BadRequestError.new(response, @options)
      when 401
        UnauthorizedError.new(response, @options)
      when 402
        PaymentRequiredError.new(response, @options)
      when 403
        ForbiddenError.new(response, @options)
      when 404
        NotFoundError.new(response, @options)
      when 405
        MethodNotAllowedError.new(response, @options)
      when 409
        ResourceConflictError.new(response, @options)
      when 422
        UnprocessableEntityError.new(response, @options)
      when 400..499
        ClientError.new(response, @options)
      when 500..599
        ServerError.new(response, @options)
      else # response.code.zero?
        ConnectionError.new(response, @options)
      end
    end
  end
end
