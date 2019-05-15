# The get, post, put, patch and delete methods return either a Response or a Error
# The bang methods get!, post!, put!, patch! and delete! raise a Error in case of failure

module ChimeraHttpClient
  class Connection < Base
    def initialize(options = {})
      super(options)

      define_bang_methods
    end

    def request
      @request ||= Request.new(logger: @logger)
    end

    def get(endpoint, options = {})
      run(:get, endpoint, options.merge(body_optional: true))
    end

    def post(endpoint, options = {})
      run(:post, endpoint, options)
    end

    def put(endpoint, options = {})
      run(:put, endpoint, options)
    end

    def patch(endpoint, options = {})
      run(:patch, endpoint, options)
    end

    def delete(endpoint, options = {})
      run(:delete, endpoint, options.merge(body_optional: true))
    end

    private

    def run(method, endpoint, options = {})
      body = extract_body(options)
      headers = extract_headers(options, default_headers)

      request.run(url: url(endpoint), method: method, body: body, options: augmented_options(options), headers: headers)
    end

    # get! post! put! patch! delete! return an Response when successful, but raise an Error otherwise
    def define_bang_methods
      {
        get!:    :get,
        post!:   :post,
        put!:    :put,
        patch!:  :patch,
        delete!: :delete,
      }.each do |method_name, implemented_method|
        self.class.send(:define_method, method_name) do |endpoint, options = {}|
          result = public_send(implemented_method, endpoint, options)

          fail result if result.error?

          result
        end
      end
    end
  end
end
