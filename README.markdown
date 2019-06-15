# ChimeraHttpClient

When starting to split monolithic apps into smaller services, you need an easy way to access the remote data from the other apps. This **chimera_http_client gem** should serve as **a comfortable and unifying way** to access endpoints from other apps.

And what works for the internal communication between your own apps, will also work for external APIs that do not offer a client for simplified access.

It offers an **easy to learn interface** and **nice error handling**. And it enables you to **queue HTTP requests to run them in parallel** for better performance and simple aggregating of distributed data.

[![Build Status](https://travis-ci.com/mediafinger/chimera_http_client.svg?branch=master)](https://travis-ci.com/mediafinger/chimera_http_client)
[![Gem Version](https://badge.fury.io/rb/chimera_http_client.svg)](https://badge.fury.io/rb/chimera_http_client)

## Dependencies

The `chimera_http_client` gem is wrapping the **libcurl** wrapper [**Typhoeus**](https://typhoeus.github.io/) to have a more convenient interface. This allows for fast requests, for caching responses, and for queueing requests to run them in parallel. Connections are persistent by default, which saves subsequent requests from establishing a connection.

The only other runtime dependency is Ruby's latest code loader [**zeitwerk**](https://github.com/fxn/zeitwerk) which is also part of Rails 6.

### Ruby version

| Chimera version | Ruby version |
|:----------------|:-------------|
| >= 1.1          | >= 2.5       |
| =  1.0          | >= 2.4       |
| <= 0.5          | >= 2.1       |

### ENV variables

Setting the environment variable `ENV['CHIMERA_HTTP_CLIENT_LOG_REQUESTS']` to `true` (or `'true'`) will provide more detailed error messages for logging and also add additional information to the Error JSON. It is recommended to use this only in development environments.

## Table of Contents

<!-- TOC depthFrom:1 depthTo:4 withLinks:1 updateOnSave:0 orderedList:0 -->

- [ChimeraHttpClient](#chimerahttpclient)
	- [Table of Contents](#table-of-contents)
	- [Dependencies](#dependencies)
		- [ENV variables](#env-variables)
	- [The Connection class](#the-connection-class)
		- [Initialization](#initialization)
			- [Mandatory initialization parameter `base_url`](#mandatory-initialization-parameter-baseurl)
			- [Optional initialization parameters](#optional-initialization-parameters)
		- [Request methods](#request-methods)
			- [Mandatory request parameter `endpoint`](#mandatory-request-parameter-endpoint)
			- [Optional request parameters](#optional-request-parameters)
			- [Basic auth](#basic-auth)
			- [Timeout duration](#timeout-duration)
			- [Custom logger](#custom-logger)
			- [Caching responses](#caching-responses)
		- [Example usage](#example-usage)
	- [The Request class](#the-request-class)
	- [The Response class](#the-response-class)
	- [Error classes](#error-classes)
	- [The Queue class](#the-queue-class)
		- [Queueing requests](#queueing-requests)
		- [Executing requests in parallel](#executing-requests-in-parallel)
	- [Installation](#installation)
	- [Maintainers and Contributors](#maintainers-and-contributors)
		- [Roadmap](#roadmap)
	- [Chimera](#chimera)

<!-- /TOC -->

## The Connection class

The basic usage looks like this:

```ruby
connection = ChimeraHttpClient::Connection.new(base_url: 'http://localhost/namespace')
response = connection.get!(endpoint, params: params)
```

### Initialization

`connection = ChimeraHttpClient::Connection.new(base_url: 'http://localhost:3000/v1', logger: logger, cache: cache)`

#### Mandatory initialization parameter `base_url`

The mandatory parameter is **base_url** which should include the host, port and base path to the API endpoints you want to call, e.g. `'http://localhost:3000/v1'`.

Setting the `base_url` is meant to be a comfort feature, as you can then pass short endpoints to each request like `/users`. You could set an empty string `''` as `base_url` and then pass full qualified URLs as endpoint of the requests.

#### Optional initialization parameters

The optional parameters are:

* `logger` - an instance of a logger class that implements `#info` and `#warn` methods
* `timeout` - the timeout for all requests, can be overwritten in any request, the default are 3 seconds
* `user_agent` - if you would like your calls to identify with a specific user agent
* `verbose` - the default is `false`, set it to true while debugging issues
* `cache` - an instance of your cache solution, can be overwritten in any request
* `deserializers` - custom methods to deserialize the response body, below more details

##### Custom deserializers

In case the API you are connecting to does not return JSON, you can pass custom deserializers to `Connection.new` or `Queue.new`:

    deserializers: { error: your_error_deserializer, response: your_response_deserializer }

A Deserializer has to be an object on which the method `call` with the parameter `body` can be called:

    custom_deserializer.call(body)

where `body` is the response body (in the default case a JSON object). The class `Deserializer` contains the default objects that are used. They might help you creating your own. Don't forget to make requests with another header than the default `"Content-Type" => "application/json"`, when the API you connect to does not support JSON.

### Request methods

The available methods are:

* `get` / `get!`
* `post` / `post!`
* `put` / `put`
* `patch` / `patch!`
* `delete` / `delete!`

where the methods ending on a _bang!_ will raise an error (which you should handle in your application) while the others will return an error object.

#### Mandatory request parameter `endpoint`

The `base_url` set in the connection will together with the `endpoint` determine the URL to make a request to.

```ruby
connection.get([:users, id])
connection.get(["users", id])
connection.get("users/#{id}")
connection.get("/users/#{id}")
```

All forms above ave valid and will make a request to the same URL.

* Please take note that _the endpoint can be given as a String, a Symbol, or an Array._  
* While they do no harm, there is _no need to pass leading or trailing `/` in endpoints._  
* When passing the endpoint as an Array, _it's elements are converted to Strings and concatenated with `/`._  

#### Optional request parameters

All request methods expect a mandatory `endpoint` and an optional hash as parameters. In the latter the following keywords are treated specially:

* `body` - the mandatory body of a `post`, `put` or `patch` request
* `headers` - a hash of HTTP headers
* `params` - parameters of a HTTP request
* `username` - used for a BasicAuth login
* `password` - used for a BasicAuth login
* `timeout` - set a custom timeout per request (the default is 3 seconds)
* `cache` - optionally overwrite the cache store set in `Connection` in any request

Example:

```ruby
connection.post(
  :users,
  body: { name: "Andy" },
  params: { origin: `Twitter`},
  headers: { "Authorization" => "Bearer #{token}" },
  timeout: 10,
  cache: nil
)
```

#### Basic auth

In case you need to use an API that is protected by **basic_auth** just pass the credentials as optional parameters:  
`username: 'admin', password: 'secret'`

#### Timeout duration

The default timeout duration is **3 seconds**.

If you want to use a different timeout, you can pass the key `timeout` when initializing the `Connection`. You can also overwrite it on every call.

#### Custom logger

By default no logging is happening. If you need request logging, you can pass your custom Logger to the key `logger` when initializing the `Connection`. It will write to `logger.info` when starting and when completing a request.

#### Caching responses

To cache all the reponses of a connection, just pass the optional parameter `cache` to its initializer. You can also overwrite the connection's cache configuration by passing the parameter `cache` to any `get` call.

It could be an instance of an implementation as simple as this:

```ruby
class Cache
  def initialize
    @memory = {}
  end

  def get(request)
    @memory[request]
  end

  def set(request, response)
    @memory[request] = response
  end
end
```

Or use an adapter for Dalli, Redis, or Rails cache that also support an optional time-to-live `default_ttl` parameter. If you use `Rails.cache` with the adapter `:memory_store` or `:mem_cache_store`, the object you would have to pass looks like this:

```ruby
require "typhoeus/cache/rails"

cache: Typhoeus::Cache::Rails.new(Rails.cache, default_ttl: 600) # 600 seconds
```

Read more about how to use it: https://github.com/typhoeus/typhoeus#caching

### Example usage

To use the gem, it is recommended to write wrapper classes for the endpoints used. While it would be possible to use the `get, get!, post, post!, put, put!, patch, patch!, delete, delete!` or also the bare `request.run` methods directly, wrapper classes will unify the usage pattern and be very convenient to use by veterans and newcomers to the team. A wrapper class could look like this:

```ruby
require 'chimera_http_client'

class Users
  def initialize(base_url: 'http://localhost:3000/v1')
    @base_url = base_url
  end

  # GET one user by id and instantiate a User
  #
  def find(id:)
    response = connection.get!(['users', id])

    user = response.parsed_body
    User.new(id: id, name: user['name'], email: user['email'])

  rescue ChimeraHttpClient::Error => error
    # handle / log / raise error
  end

  # GET a list of users and instantiate an Array of Users
  #
  def all(filter: nil, page: nil)
    params = {}
    params[:filter] = filter
    params[:page] = page

    response = connection.get!('users', params: params, timeout: 10) # set longer timeout

    all_users = response.parsed_body
    all_users.map { |user| User.new(id: user['id'], name: user['name'], email: user['email']) }

  rescue ChimeraHttpClient::Error => error
    # handle / log / raise error
  end

  # CREATE a new user by sending attributes in a JSON body and instantiate the new User
  #
  def create(body:)
    response = connection.post!('users', body: body.to_json) # body.to_json (!!)

    user = response.parsed_body
    User.new(id: user['id'], name: user['name'], email: user['email'])

  rescue ChimeraHttpClient::Error => error
    # handle / log / raise error
  end

  private

  def connection
    # base_url is mandatory
    # logger and timeout are optional
    @connection ||= ChimeraHttpClient::Connection.new(base_url: @base_url, logger: Logger.new(STDOUT), timeout: 2)
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

Usually it does not have to be used directly. It is the class that executes the `Typhoeus::Requests`, raises `Errors` on failing and returns `Response` objects on successful calls.

The `body` which it receives from the `Connection` class has to be in the in the (serialized) form in which the endpoint expects it. Usually this means you have to pass a JSON string to the `body` (it will **not** be serialized automatically).

## The Response class

The `ChimeraHttpClient::Response` objects have the following interface:

    * body             (content the call returns)
    * code             (http code, should be 200 or 2xx)
    * time             (for monitoring)
    * response         (the full response object, including the request)
    * error?           (returns false)
    * parsed_body      (returns the result of `deserializer[:response].call(body)`)

If your API does not use JSON, but a different format e.g. XML, you can pass a custom deserializer to the Connection.

## Error classes

All errors inherit from `ChimeraHttpClient::Error` and therefore offer the same attributes:

    * code             (http error code)
    * body             (alias => message)
    * time             (for monitoring)
    * response         (the full response object, including the request)
    * error?           (returns true)
    * error_class      (e.g. ChimeraHttpClient::NotFoundError)
    * to_s             (information for logging / respects ENV['CHIMERA_HTTP_CLIENT_LOG_REQUESTS'])
    * to_json          (information to return to the API consumer / respects ENV['CHIMERA_HTTP_CLIENT_LOG_REQUESTS'])

The error classes and their corresponding http error codes:

    ConnectionError           # 0
    RedirectionError          # 301, 302, 303, 307
    BadRequestError           # 400
    UnauthorizedError         # 401
    ForbiddenError            # 403
    NotFoundError             # 404
    MethodNotAllowedError     # 405
    ResourceConflictError     # 409
    UnprocessableEntityError  # 422
    ClientError               # 400..499
    ServerError               # 500..599
    TimeoutError              # timeout

## The Queue class

Instead of making single requests immediately, the ChimeraHttpClient allows to queue requests and run them in **parallel**.

The number of parallel requests is limited by your system. There is a hard limit for 200 concurrent requests. You will have to measure yourself where the sweet spot for optimal performance is - and when things start to get flaky. I recommend to queue not much more than 20 requests before running them.

### Queueing requests

The initializer of the `Queue` class expects and handles the same parameters as the `Connection` class.

```ruby
queue = ChimeraHttpClient::Queue.new(base_url: 'http://localhost:3000/v1')
```

`queue.add` expects and handles the same parameters as the requests methods of a connection.

```ruby
queue.add(method, endpoint, options = {})
```

The only difference is that a parameter to set the HTTP method has to prepended. Valid options for `method` are:

* `:get` / `'get'` / `'GET'`
* `:post` / `'post'` / `'POST'`
* `:put` / `'put'` / `'PUT'`
* `:patch` / `'patch'` / `'PATCH'`
* `:delete` / `'delete'` / `'DELETE'`

### Executing requests in parallel

Once the queue is filled, run all the requests concurrently with:

```ruby
responses = queue.execute
```

`responses` will contain an Array of `ChimeraHttpClient::Response` objects when all calls succeed. If any calls fail, the Array will also contain `ChimeraHttpClient::Error` objects. It is in your responsibility to handle the errors.

> Tip: every `Response` and every `Error` make the underlying `Typheous::Request` available over `object.response.request`, which could help with debugging, or with building your own retry mechanism.

### Empty the queue

The queue is emptied after execution. You could also empty it at any other point before by calling `queue.empty`.

To inspect the requests waiting for execution, call `queue.queued_requests`.

## Installation

Add this line to your application's Gemfile:

    gem 'chimera_http_client', '~> 1.1'

And then execute:

    $ bundle

When updating the version, do not forget to run

    $ bundle update chimera_http_client

## Maintainers and Contributors

After checking out the repo, run `bundle install` and then `bundle execute rake` to run the **tests and rubocop**.

> The test suite uses a Sinatra server to make real HTTP requests. It is mounted via Capybara_discoball and running in the same process. It is still running reasonably fast (on my MacBook Air):

    Finished in 2.01 seconds (files took 1.09 seconds to load)
    824 examples, 0 failures, 7 pending

You can also run `rake console` to open an irb session with the `ChimeraHttpClient` pre-loaded that will allow you to experiment.

To build and install this gem onto your local machine, run `bundle exec rake install`.

> Maintainers only:
>
> To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Bug reports and pull requests are welcome on GitHub at <https://github.com/mediafinger/chimera_http_client>

### Roadmap

https://github.com/mediafinger/chimera_http_client/blob/master/TODO.markdown

## Chimera

Why this name? First of all, I needed a unique namespace. _HttpClient_ is already used too often. And as this gem is based on **Typhoeus** I picked the name of one of his (mythological) children.

<https://en.wikipedia.org/wiki/Chimera_(mythology)>
