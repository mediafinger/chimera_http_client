module ChimeraHttpClient
  class Base
    USER_AGENT = "ChimeraHttpClient (by mediafinger)".freeze

    def initialize(base_url:, logger: nil, timeout: nil, user_agent: USER_AGENT, verbose: false, cache: nil)
      fail(ChimeraHttpClient::ParameterMissingError, "base_url expected, but not given") if base_url.nil?

      @base_url = base_url
      @logger = logger
      @timeout = timeout

      Typhoeus::Config.user_agent = user_agent
      Typhoeus::Config.verbose = verbose
      Typhoeus::Config.memoize = false
      Typhoeus::Config.cache = cache
    end

    private

    # Add default values to call options
    def augmented_options(options)
      options[:timeout] ||= @timeout

      options
    end

    def extract_body(options)
      body = options.delete(:body)
      body_optional = options.delete(:body_optional)
      fail(ChimeraHttpClient::ParameterMissingError, "body expected, but not given") if body.nil? && !body_optional
      body
    end

    def extract_headers(options, headers)
      given_headers = options.delete(:headers) || {}
      headers.merge(given_headers)
    end

    def default_headers
      { "Content-Type" => "application/json" }
    end

    # Build URL out of @base_url and endpoint given as String or Array, while trimming redundant "/"
    def url(endpoint)
      trimmed_endpoint = Array(endpoint).map { |e| trim(e) }
      [@base_url.chomp("/"), trimmed_endpoint].flatten.reject(&:empty?).join("/")
    end

    # Remove leading and trailing "/" from a give part of a String (usually URL or endpoint)
    def trim(element)
      element.to_s.sub(%r{^\/}, "").chomp("/")
    end
  end
end
