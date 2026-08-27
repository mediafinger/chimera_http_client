# ChimeraHttpClient

When starting to split monolithic apps into smaller services, you need an easy way to access the remote data from the other apps. This **chimera_http_client gem** should serve as **a comfortable and unifying way** to access endpoints from other apps.

And what works for the internal communication between your own apps, will also work for external APIs that do not offer a client for simplified access.

It offers an **easy to learn interface** and **nice error handling**. And it enables you to **queue HTTP requests to run them in parallel** for better performance and simple aggregating of distributed data.

[![GitHub Actions CI Build Status](https://github.com/mediafinger/chimera_http_client/actions/workflows/action-ci.yml/badge.svg?branch=master)](https://github.com/mediafinger/chimera_http_client/actions/workflows/action-ci.yml)
[![Gem Version](https://badge.fury.io/rb/chimera_http_client.svg)](https://badge.fury.io/rb/chimera_http_client)

## Dependencies

The `chimera_http_client` gem is wrapping the **libcurl** wrapper [**Typhoeus**](https://typhoeus.github.io/) to have a more convenient interface. This allows for fast requests, for caching responses, and for queueing requests to run them in parallel. Connections are persistent by default, which saves subsequent requests from establishing a connection.

The only other runtime dependency is Ruby's latest code loader [**zeitwerk**](https://github.com/fxn/zeitwerk) which is also part of Rails 6.
^
### Ruby version

| Chimera version | MRI Ruby version                                                     | JRuby | TruffleRuby |
|:----------------|:---------------------------------------------------------------------|:-----:|:-----------:|
| >= 1.8          | >= 3.3 (4.0 supported, older versions untested, likely still work)   |  yes  |     yes     |
| >= 1.7          | >= 3.3 (older versions untested, likely still work)                  |  yes  |     yes     |
| >= 1.6          | >= 2.7 (all 3.x versions supported)                                  |  yes  |     yes     |
| >= 1.4          | >= 2.5 (3.0 compatibility ensured)                                   |  yes  |     no      |
| >= 1.1          | >= 2.5                                                               |   ?   |      ?      |
| =  1.0          | >= 2.4, <= 3.0                                                       |   ?   |      ?      |
| <= 0.5          | >= 2.1, <= 3.0                                                       |   ?   |      ?      |

The test suite of v1.4 passes on **MRI Ruby** (2.5, 2.6, 2.7, 3.0) and on **JRuby**, but not on **TruffleRuby**.  
The test suite of v1.6 passes on **MRI Ruby** (2.7, 3.0, 3.1, 3.2, 3.3) and on **JRuby** and **TruffleRuby**.  
v1.8 is no longer tested against MRI Rubies older than 3.3 (but they are likely still supported).  
All information above is given for **Linux**.  
**MacOS & Windows** were only tested successfully against **MRI Ruby 4.0** (older versions likely work as well).

### ENV variables

Setting the environment variable `ENV['CHIMERA_HTTP_CLIENT_LOG_REQUESTS']` to `true` (or `'true'`) will provide more detailed error messages for logging and also add additional information to the Error JSON. It is recommended to use this only in development environments.

Setting `ENV['CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS']` to a JSON object string will merge those headers into every `Connection`/`Queue` in the process, e.g. `export CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS='{"X-Service-Name":"orders-api"}'`. This is meant for deployment/ops-level defaults (like identifying which service is calling), set once outside application code. See [Custom headers](#custom-headers) below.

## Table of Contents

<!-- TOC depthFrom:1 depthTo:4 withLinks:1 updateOnSave:0 orderedList:0 -->

- [ChimeraHttpClient](#chimerahttpclient)
  - [Dependencies](#dependencies)
    - [Ruby version](#ruby-version)
    - [ENV variables](#env-variables)
  - [Table of Contents](#table-of-contents)
  - [The Connection class](#the-connection-class)
    - [Initialization](#initialization)
      - [Mandatory initialization parameter `base_url`](#mandatory-initialization-parameter-base_url)
      - [Optional initialization parameters](#optional-initialization-parameters)
        - [Custom deserializers](#custom-deserializers)
        - [Custom headers](#custom-headers)
        - [Custom serializer](#custom-serializer)
        - [Monitoring, metrics, instrumentation](#monitoring-metrics-instrumentation)
    - [Request methods](#request-methods)
      - [Mandatory request parameter `endpoint`](#mandatory-request-parameter-endpoint)
      - [Optional request parameters](#optional-request-parameters)
      - [Basic auth](#basic-auth)
      - [Timeout duration](#timeout-duration)
      - [Retrying requests](#retrying-requests)
      - [Custom logger](#custom-logger)
      - [Caching responses](#caching-responses)
    - [Example usage](#example-usage)
  - [The Request class](#the-request-class)
  - [The Response class](#the-response-class)
  - [Error classes](#error-classes)
  - [The Queue class](#the-queue-class)
    - [Queueing requests](#queueing-requests)
    - [Executing requests in parallel](#executing-requests-in-parallel)
    - [Empty the queue](#empty-the-queue)
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

* `cache` - an instance of your cache solution, can be overwritten in any request
* `deserializers` - custom methods to deserialize the response body, below more details
* `headers` - override/extend the default request headers (`{ "Content-Type" => "application/json" }`), can be overwritten or merged with per-request headers, below more details
* `logger` - an instance of a logger class that implements `#info`, `#warn` and `#error` methods
* `monitor` - to collect metrics about requests, the basis for your instrumentation needs
* `retries` - the number of times a failed idempotent request is retried, can be overwritten in any request, the default is `0` (no retries)
* `retry_delay` - the base delay in seconds between retries, can be overwritten in any request, the default is `1`
* `serializer` - override how a Hash/Array request body is turned into a request, can be overwritten in any request, below more details
* `timeout` - the timeout for all requests, can be overwritten in any request, the default are 3 seconds
* `user_agent` - if you would like your calls to identify with a specific user agent
* `verbose` - the default is `false`, set it to true while debugging issues

##### Custom deserializers

In case the API you are connecting to does not return JSON, you can pass custom deserializers to `Connection.new` or `Queue.new`:

    deserializers: { error: your_error_deserializer, response: your_response_deserializer }

A Deserializer has to be an object on which the method `call` with the parameter `body` can be called:

    custom_deserializer.call(body)

where `body` is the response body (in the default case a JSON object). The class `Deserializer` contains the default objects that are used. They might help you creating your own. If the API you connect to does not support JSON, set `headers` (see [Custom headers](#custom-headers) below) once on the `Connection` instead of repeating it on every request - and see [Custom serializer](#custom-serializer) below for the equivalent on the request-body side.

##### Custom headers

Every request sends `{ "Content-Type" => "application/json" }` plus a `User-Agent` by default. Four layers apply on top of each other (each one merges in, overriding only the keys it sets, so you never have to restate headers you're not changing):

1. the built-in default above (also available as `ChimeraHttpClient::Base::DEFAULT_HEADERS`)
2. `ENV['CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS']`, a JSON object (see [ENV variables](#env-variables) above)
3. `headers` passed to `Connection.new`/`Queue.new` - the connection's own default
4. `headers` passed to an individual request - already documented above, unchanged

```ruby
# connecting to a non-JSON API: override just Content-Type, everything else (User-Agent, ...) still applies
connection = ChimeraHttpClient::Connection.new(base_url: 'http://localhost:3000/v1', headers: { "Content-Type" => "application/xml" })
```

A common use for the connection-level `headers` option is a request/correlation id that should be attached to every call made for one unit of work (a background job, one inbound request being served), without every call site needing to know about it:

```ruby
connection = ChimeraHttpClient::Connection.new(base_url: 'http://localhost:3000/v1', headers: { "X-Request-Id" => job_id })
```

For something that's the same for every request in the whole process instead - e.g. identifying which of your services is calling, in a service-to-service setting - set it once via `ENV['CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS']` at the deployment level rather than in application code:

```bash
export CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS='{"X-Service-Name":"orders-api"}'
```

##### Custom serializer

A `Hash` or `Array` `body` is automatically serialized before the request is sent - by default with `body.to_json`, so this now just works:

```ruby
connection.post!('users', body: { name: "Andy" }) # no more body.to_json needed
```

A `String` body (e.g. one you already serialized yourself) is always passed through completely unchanged - so any existing code still doing `body: body.to_json` keeps working exactly as before.

To use a different format, pass `serializer` to `Connection.new`/`Queue.new`, or to an individual request. A Serializer has to be an object on which the method `call` with the parameter `body` can be called:

    custom_serializer.call(body)

```ruby
# talking to an XML API instead
connection = ChimeraHttpClient::Connection.new(base_url: 'http://localhost:3000/v1', serializer: ->(body) { body.to_xml })
```

The serializer normally returns a `String`, but it can also return the `Hash` unconverted - Typhoeus (via Ethon/libcurl) then form-encodes it natively as `application/x-www-form-urlencoded`, or as real multipart if a value looks file-shaped:

```ruby
# posting a plain form instead of JSON
connection.post(
  'login',
  body: { username: "andy", password: "secret" },
  serializer: ->(body) { body }, # hand the Hash to Typhoeus/Ethon unconverted
  headers: { "Content-Type" => "application/x-www-form-urlencoded" }
)
```

##### Monitoring, metrics, instrumentation

Pass an object as `:monitor` to a connection that defines the method `call` and accepts a hash as parameter.

    monitor.call({...})

It will receive information about every request as soon as it finished. What you do with this information is up for you to implement.

| Field          | Description                                                           |
|:---------------|:----------------------------------------------------------------------|
| `url`          | URL of the endpoint that was called                                   |
| `method`       | HTTP method: get, post, ...                                           |
| `status`       | HTTP status code: 200, ...                                            |
| `runtime`      | the time in seconds it took the request to finish                     |
| `completed_at` | Time.now.utc.iso8601(3)                                               |
| `context`      | Whatever you pass as `monitoring_context` to the options of a request |

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
* `retries` - optionally overwrite the number of retries set in `Connection` for this request
* `retry_delay` - optionally overwrite the retry delay set in `Connection` for this request
* `serializer` - optionally overwrite the body serializer set in `Connection` for this request
* `monitoring_context` - pass additional information you want to collect with your instrumentation `monitor`

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

#### Retrying requests

Pass `retries` (and optionally `retry_delay`) to `Connection.new`/`Queue.new`, or to any individual request, to automatically retry on transient failures:

```ruby
connection = ChimeraHttpClient::Connection.new(base_url: 'http://localhost:3000/v1', retries: 3, retry_delay: 1)
```

* `retries` - the maximum number of retry attempts. The default is `0` (no retries, fully opt-in).
* `retry_delay` - the base delay in seconds before the first retry. The default is `1`. Each subsequent retry doubles the previous delay (a fixed 2x backoff, not configurable): with `retry_delay: 1` the delays are `1s, 2s, 4s, ...`.

Retries are automatic and safe by design - they only apply to:

* **idempotent methods**: `get`, `put`, `delete`, `head` - never `post`/`patch`, regardless of the configured `retries`, since retrying a non-idempotent write could duplicate side effects.
* **transient errors**: `ConnectionError`, `TimeoutError`, `ServerError` (5xx) - never 4xx `ClientError`s, since retrying those can't change the outcome.

> Note for `Queue`: retries are implemented by re-queueing the failed request onto the same `Typhoeus::Hydra` that's already running the batch, so a retry can start as soon as its own request fails rather than waiting for the whole batch. One consequence: the `retry_delay` sleep happens inside that request's completion callback, which briefly pauses progress on *every other* in-flight request in the same queue (libcurl's multi interface is a single-threaded, cooperative event loop). This doesn't affect `Connection`, whose retries run sequentially with nothing else in flight.

#### Custom logger

By default no logging is happening. If you need request logging, you can pass your custom Logger to the key `logger` when initializing the `Connection`. It will write to `logger.info` when starting and when completing a request.

The message passed to the logger is a hash with the following fields:

| Key          | Description                                 |
|:-------------|:--------------------------------------------|
| `message`    | indicator if a call was started or finished |
| `method`     | the HTTP method used                        |
| `url`        | the requested URL                           |
| `code`       | HTTP status code                            |
| `runtime`    | time the request took in ms                 |
| `user_agent` | the user_agent used to open the connection  |

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
    response = connection.post!('users', body: body) # a Hash body is serialized to JSON automatically

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

By the time `Request` receives `body`, it's already in the (serialized) form the endpoint expects: `Connection`/`Queue` auto-serialize a `Hash`/`Array` body to JSON (or via a custom `serializer`, see [Custom serializer](#custom-serializer)) before it ever reaches `Request`. A `String` body is passed through unchanged.

## The Response class

The `ChimeraHttpClient::Response` objects have the following interface:

    * body             (content the call returns)
    * code             (http code, should be 200 or 2xx)
    * time             (for monitoring)
    * response         (the full response object, including the request)
    * success?         (returns the result of response.success?)
    * error?           (returns false)
    * parsed_body      (returns the result of `deserializer[:response].call(body)`)

If your API does not use JSON, but a different format e.g. XML, you can pass a custom deserializer to the Connection.

## Error classes

All errors inherit from `ChimeraHttpClient::Error` and therefore offer the same attributes:

    * code             (http error code)
    * body             (alias => message)
    * time             (for monitoring)
    * response         (the full response object, including the request)
    * success?         (returns the result of response.success?)
    * error?           (returns true)
    * error_class      (e.g. ChimeraHttpClient::NotFoundError)
    * to_s             (information for logging / respects ENV['CHIMERA_HTTP_CLIENT_LOG_REQUESTS'])
    * to_json          (information to return to the API consumer / respects ENV['CHIMERA_HTTP_CLIENT_LOG_REQUESTS'])

The error classes and their corresponding http error codes:

    ConnectionError           # 0
    RedirectionError          # 301, 302, 303, 307
    BadRequestError           # 400
    UnauthorizedError         # 401
    PaymentRequiredError      # 402
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

    Finished in 1.02 seconds (files took 0.43805 seconds to load)  
    882 examples, 0 failures, 7 pending

You can also run `rake console` to open an irb session with the `ChimeraHttpClient` pre-loaded that will allow you to experiment.

To build and install this gem onto your local machine, run `bundle exec rake install`.

> Maintainers only:
>
> To release a new version, update the version number in `version.rb`, commit this change, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Bug reports and pull requests are welcome on GitHub at <https://github.com/mediafinger/chimera_http_client>

### Roadmap

https://github.com/mediafinger/chimera_http_client/blob/master/TODO.markdown

## Chimera

Why this name? First of all, I needed a unique namespace. _HttpClient_ is already used too often. And as this gem is based on **Typhoeus** I picked the name of one of his (mythological) children.

<https://en.wikipedia.org/wiki/Chimera_(mythology)>
