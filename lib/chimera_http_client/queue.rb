module ChimeraHttpClient
  class Queue < Base
    def add(method, endpoint, options = {})
      http_method = method.downcase.to_sym
      options[:body_optional] = true if %i[get delete].include?(http_method)

      body = extract_body(options)
      headers = extract_headers(options, default_headers)

      req = Request.new(logger: @logger).create(
        url: url(endpoint),
        method: http_method,
        body: body,
        options: augmented_options(options),
        headers: headers
      )

      queued_requests << req
    end

    def execute
      queued_requests.each do |request|
        hydra.queue(request.request)
      end

      hydra.run

      responses = queued_requests.map { |request| request.result }

      empty

      responses
    end

    def empty
      @queued_requests = []
    end

    def queued_requests
      @queued_requests ||= []
    end

    private

    def hydra
      @hydra ||= Typhoeus::Hydra.new
    end
  end
end
