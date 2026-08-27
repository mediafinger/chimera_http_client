module ChimeraHttpClient
  class Base
    USER_AGENT = "ChimeraHttpClient (by mediafinger)".freeze
    DEFAULT_HEADERS = { "Content-Type" => "application/json" }.freeze
    DEFAULT_HEADERS_ENV_VAR = "CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS".freeze

    def initialize(options = {})
      fail(ChimeraHttpClient::ParameterMissingError, "base_url expected, but not given") if options[:base_url].nil?

      @base_url = options.fetch(:base_url)
      @deserializer = default_deserializer.merge(options.fetch(:deserializer, {}))
      @logger = options[:logger]
      @monitor = options[:monitor]
      @timeout = options[:timeout]
      @cache = options[:cache]
      @headers = DEFAULT_HEADERS.merge(headers_from_env).merge(options[:headers] || {})
      @user_agent = options.fetch(:user_agent, USER_AGENT)
      @verbose = options.fetch(:verbose, false)
      @retries = options[:retries] || 0
      @retry_delay = options[:retry_delay] || 1
    end

    private

    # Add default values to call options
    def augmented_options(options)
      options[:timeout] ||= @timeout
      options[:cache] = @cache if options[:cache].nil?
      options[:verbose] = @verbose if options[:verbose].nil?
      options[:retries] = @retries if options[:retries].nil?
      options[:retry_delay] = @retry_delay if options[:retry_delay].nil?

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
      @headers.merge("User-Agent" => @user_agent)
    end

    def headers_from_env
      raw = ENV[DEFAULT_HEADERS_ENV_VAR].to_s
      return {} if raw.strip.empty?

      JSON.parse(raw)
    rescue JSON::ParserError => e
      raise(ChimeraHttpClient::ParameterMissingError, "ENV['#{DEFAULT_HEADERS_ENV_VAR}'] is not valid JSON: #{e.message}")
    end

    def default_deserializer
      { error: ::ChimeraHttpClient::Deserializer.json_error, response: ::ChimeraHttpClient::Deserializer.json_response }
    end

    # Build URL out of @base_url and endpoint given as String or Array, while trimming redundant "/"
    def url(endpoint)
      trimmed_endpoint = Array(endpoint).map { |e| trim(e) }
      [@base_url.chomp("/"), trimmed_endpoint].flatten.reject(&:empty?).join("/")
    end

    # Remove leading and trailing "/" from a give part of a String (usually URL or endpoint)
    def trim(element)
      element.to_s.sub(%r{^/}, "").chomp("/")
    end
  end
end
