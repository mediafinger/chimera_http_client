# The get, post, put, patch and delete methods return either a Response or a Error
# The bang methods get!, post!, put!, patch! and delete! raise a Error in case of failure

module ChimeraHttpClient
  class Connection < Base
    def initialize(options = {})
      super(options)

      define_http_methods
      define_bang_methods
    end

    def request
      options = {
        deserializer: @deserializer,
        logger: @logger,
        monitor: @monitor,
      }

      Request.new(options)
    end

    private

    def run(method, endpoint, options = {})
      options[:body_optional] = true if %i[get delete head options trace].include?(method)
      body = extract_body(options)
      headers = extract_headers(options, default_headers)

      request.run(url: url(endpoint), method: method, body: body, options: augmented_options(options), headers: headers)
    end

    # Define simple access methods that return a Response object in success case and an Error object otherwise
    #
    # def get(endpoint, options = {})
    #   run(:get, endpoint, options)
    # end
    #
    def define_http_methods
      %i[get post put patch delete head options trace].each do |method_name|
        self.class.send(:define_method, method_name) do |endpoint, options = {}|
          send(:run, method_name, endpoint, options)
        end
      end
    end

    # get! post! put! patch! delete! ... return a Response object when successful, but raise an Error otherwise
    def define_bang_methods
      {
        get!:     :get,
        post!:    :post,
        put!:     :put,
        patch!:   :patch,
        delete!:  :delete,
        head!:    :head,
        options!: :options,
        trace!:   :trace,
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
