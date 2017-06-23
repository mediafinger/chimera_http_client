# The get, post, put, patch and delete methods return either a Response or a HttpError
# The bang methods get!, post!, put!, patch! and delete! raise a HttpError in case of failure

module HttpClient
  class Connection
    USER_AGENT = "HttpClient (by mediafinger)".freeze

    def initialize(base_url:, user_agent: USER_AGENT, verbose: false)
      fail(HttpClient::ParameterMissingError, "base_url expected, but not given") if base_url.nil?
      @base_url = base_url

      define_bang_methods

      Typhoeus::Config.user_agent = user_agent
      Typhoeus::Config.verbose = verbose
      Typhoeus::Config.memoize = false
      # Typhoeus::Config.cache
    end

    def request
      @request ||= Request.new
    end

    def get(endpoint, options = {}, &block)
      headers = extract_headers(options, default_headers)

      request.run(url: url(endpoint), method: :get, options: options, headers: headers, &block)
    end

    def post(endpoint, options = {})
      run_with_body(:post, endpoint, options)
    end

    def put(endpoint, options = {})
      run_with_body(:put, endpoint, options)
    end

    def patch(endpoint, options = {})
      run_with_body(:patch, endpoint, options)
    end

    def delete(endpoint, options = {})
      run_with_body(:delete, endpoint, options.merge(body_optional: true))
    end

    private

    def run_with_body(method, endpoint, options = {}, &block)
      body = extract_body(options)
      headers = extract_headers(options, default_headers)

      request.run(url: url(endpoint), method: method, body: body, options: options, headers: headers, &block)
    end

    def url(endpoint)
      trimmed_endpoint = trimmed_string(Array(endpoint).map(&:to_s).flatten.compact.join("/"))
      [@base_url.chomp("/"), trimmed_endpoint].flatten.compact.join("/")
    end

    def trimmed_string(string)
      string.sub(%r{^\/}, "").chomp("/")
    end

    def extract_body(options)
      body = options.delete(:body)
      body_optional = options.delete(:body_optional)
      fail(HttpClient::ParameterMissingError, "body expected, but not given") if body.nil? && !body_optional
      body
    end

    def extract_headers(options, headers)
      given_headers = options.delete(:headers) || {}
      headers.merge(given_headers)
    end

    def default_headers
      { "Content-Type" => "application/json" }
    end

    # get! post! put! patch! delete! return an Response when successful, but raise an HttpError otherwise
    def define_bang_methods
      {
        get!:    :get,
        post!:   :post,
        put!:    :put,
        patch!:  :patch,
        delete!: :delete,
      }.each do |method_name, implemented_method|
        self.class.send(:define_method, method_name) do |endpoint, options = {}, &block|
          result = public_send(implemented_method, endpoint, options, &block)

          fail result if result.error?

          result
        end
      end
    end
  end
end
