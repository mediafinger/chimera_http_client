# HttpClient

When starting to split monolithic apps into smaller services, you need an easy way to access the remote data from the other apps. This http-client gem should serve as a unified way to access endpoints from other apps. And what works for the internal communication between your own apps, will also work to work with external APIs that do not offer a client for simplified access.

## Dependencies

The `http-client` gem is using the _libcurl_ wrapper [**Typhoeus**](https://typhoeus.github.io/). This allows for fast requests, for caching, and for queueing requests to run them in parallel (queueing and parallel requests are not implemented in the gem yet).

It does not have any other runtime dependencies.

### optional

Setting the environment variable `ENV['HTTP_CLIENT_LOG_REQUESTS']` to `true` (or `'true'`) will provide more detailed error messages for logging and also add additional information to the HttpError JSON. It is recommended to use this only in development environments.

## The Connection class

The basic usage looks like this:

```ruby
connection = HttpClient::Connection.new(base_url: 'http://localhost/namespace')
response = connection.get!(endpoint, params: params)
```

`HttpClient::Connection.new` expects an options hash as parameter. The only required option is **base_url** which should include the host, port and base path to the API endpoints you want to call, e.g.  
`base_url: 'http://localhost:3000/v1'`.

On this connection object, you can call methods like `#get!` or `#post!` with an endpoint and an options hash as parameters, e.g.  
`connection.get!("users/#{id}")` or  
`connection.get(['users', id], options: { headers: { '	Accept-Charset' => 'utf-8' })`  

Please take note that _the endpoint can be given as a String, a Symbol, or as an Array._  
While they do no harm, there is _no need to pass leading or trailing `/` in endpoints._
When passing the endpoint as an Array, _it's elements are converted to Strings and concatenated with `/`._  
On each request _the http-headers can be amended or overwritten_ completely or partially.

In case you need to use an API that is protected by **basic_auth** just pass the credentials in the options hash:  
`options: { username: 'admin', password: 'secret' }`

### Example usage

To use the gem, it is recommended to write wrapper classes for the endpoints used. While it would be possible to use the `get, get!, post, post!, put, put!, patch, patch!, delete, delete!` or also the bare `request.run` methods directly, wrapper classes will unify the usage pattern and be very convenient to use by veterans and newcomers to the team. A wrapper class could look like this:

```ruby
require 'http_client'

class Users
  def initialize(base_url: 'http://localhost:3000/v1')
    @base_url = base_url
  end

  def find(id:)
    response = connection.get!(['users', id])

    user = response.parsed_body
    User.new(id: id, name: user['name'], email: user['email'])

  rescue HttpClient::HttpError => error
    # handle / log / raise error
  end

  def all(filter: nil, page: nil)
    params = {}
    params[:filter] = filter
    params[:page] = page

    response = connection.get!('users', params: params)

    all_users = response.parsed_body
    all_users.map { |user| User.new(id: user['id'], name: user['name'], email: user['email']) }

  rescue HttpClient::HttpError => error
    # handle / log / raise error
  end

  def create(body:)
    response = connection.post!('users', body: body.to_json) # body.to_json

    user = response.parsed_body
    User.new(id: user['id'], name: user['name'], email: user['email'])

  rescue HttpClient::HttpError => error
    # handle / log / raise error
  end

  private

  def connection
    @connection ||= HttpClient::Connection.new(base_url: @base_url)
  end
end
```

To create and fetch a user from a remote service with the `Users` wrapper listed above, calls could be made like this:

```ruby
  users = Users.new

  new_user = users.create(body: { name: "Andy", email: "andy@example.com" })
  id = new_user.id

  user = users.find(id: id)
  user.name # == "Andy"
```

## The Request class

Usually it does not have to be used directly. It is the class that executes the `Typhoeus::Requests`, raises `HttpErrors` on failing and returns `Response` objects on successful calls.

It will be expanded by a `.queue` method, that will queue (sic) calls and run them in parallel and not run every call directly, like the `.run` method does.

## The Response class

The `HttpClient::Response` objects have the following interface:

    * body             (content the call returns)
    * code             (http code, should be 200 or 2xx)
    * time             (for monitoring)
    * response         (the full response object, including the request)
    * error?           (returns false)
    * parsed_body      (returns the result of JSON.parse(body))

If your API does not use JSON, but a different format e.g. XML, you can either monkey patch a `parsed_xml` method to the Response class, or let your wrapper handle the parsing of `body`.

## HttpError classes

All errors inherit from `HttpClient::HttpError` and therefore offer the same attributes:

    * code             (http error code)
    * body             (alias => message)
    * time             (for monitoring)
    * response         (the full response object, including the request)
    * error?           (returns true)
    * error_class      (e.g. HttpClient::HttpNotFoundError)
    * to_s             (information for logging / respects ENV['HTTP_CLIENT_LOG_REQUESTS'])
    * to_json          (information to return to the API consumer / respects ENV['HTTP_CLIENT_LOG_REQUESTS'])

The error classes and their corresponding http error codes:

    HttpConnectionError           # 0
    HttpRedirectionError          # 301, 302, 303, 307
    HttpBadRequestError           # 400
    HttpUnauthorizedError         # 401
    HttpForbiddenError            # 403
    HttpNotFoundError             # 404
    HttpMethodNotAllowedError     # 405
    HttpResourceConflictError     # 409
    HttpUnprocessableEntityError  # 422
    HttpClientError               # 400..499
    HttpServerError               # 500..599
    HttpTimeoutError              # timeout

## Installation

Add this line to your application's Gemfile:

    gem 'http-client', '~> 0.1'

And then execute:

    $ bundle

When updating the version, do not forget to run

    $ bundle update http-client

## Development

After checking out the repo, run `rake` to run the **tests and rubocop**.

You can also run `rake console` to open an irb session with the `HttpClient` pre-loaded that will allow you to experiment.

### Maintainers and Contributors

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Bug reports and pull requests are welcome on GitHub at <https://github.com/mediafinger/http-client>
