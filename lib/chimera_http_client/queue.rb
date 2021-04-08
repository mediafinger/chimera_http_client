module ChimeraHttpClient
  class Queue < Base
    def add(method, endpoint, options = {})
      http_method = method.downcase.to_sym
      options[:body_optional] = true if %i(get delete head options trace).include?(http_method)

      queued_requests << create_request(
        method: http_method,
        url: url(endpoint),
        body: extract_body(options),
        headers: extract_headers(options, default_headers),
        options: augmented_options(options)
      )
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

    def create_request(method:, url:, body:, headers:, options:)
      instance_options = {
        deserializer: @deserializer,
        logger: @logger,
        monitor: @monitor,
      }

      Request.new(instance_options).create(
        method: method,
        url: url,
        body: body,
        headers: headers,
        options: options
      )
    end

    def hydra
      @hydra ||= Typhoeus::Hydra.new
    end
  end
end
