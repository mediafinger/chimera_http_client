# ChimeraHttpClient TODOs

## Bugs

_none known_

## Features

### Logger

* [x] ~~allow to pass a logger~~
* [x] ~~add logger.info when starting a http call~~
* [x] ~~add logger.info when finishing a successful http call~~
* [x] ~~include the total_time of the requests in the log~~
* [x] ~~add (example) to README~~
* [ ] add logger.warn / .error for error cases (?)
* [ ] streamline log message

### ~~Custom De-serializer~~

* [x] ~~allow to pass custom deserializer~~
* [x] ~~use custom deserializer in #parsed_body instead of default JSON parsing~~
* [x] ~~add example to README~~

### Queueing / running in parallel

* [x] ~~allow to queue multiple requests~~
* [x] ~~execute (up to 200) requests in parallel~~
* [ ] allow to pass one proc / block (for all requests) to use as on_complete handler for each request
* [ ] allow to pass one proc / block per requests) to use as on_complete handler
* [ ] add example to README

### Add server for testing

* [x] ~~add a simple (Sinatra) server for testing~~
* [x] ~~run (all?) tests against the server (with capybara_discoball)~~
* [ ] make server also available for console testing
* [ ] add example to README

### Miscellaneous

- [ ] Determine by parameter if 3xx Redirects should be handled as an Error or not
- [x] ~~Add a longer description to the gemspec file~~
- [ ] Refactor README to explain simple use case vs. all the powerful options?

### ~~Instrumentation~~

- [x] ~~allow to pass object to collect metrics for monitoring~~
  - [x] ~~request URL~~
  - [x] ~~request HTTP method~~
  - [x] ~~request response code~~
  - [x] ~~request datetime~~
  - [x] ~~request runtime~~
  - [x] ~~custom context information per request~~
- [x] ~~add example to README~~

### Enable more Typhoeus functionality

* [ ] accept_encoding: "gzip"
* [ ] connecttimeout: 1
* [ ] cookiefile: "/path/to/file"
* [ ] cookiejar: "/path/to/file"
* [ ] followlocation: true
* [ ] forbid_reuse: true
* [ ] memoize: false
* [ ] ssl_verifyhost: 0
* [ ] ssl_verifypeer: false
* [ ] verbose: true
* [ ] Cache adapters
* [ ] or enable to access the Typhoeos directly through Chimera?
* [ ] add example to README

### File Uploads

* [ ] add example to README

### Streaming response bodies

* [ ] enable to pass on_headers, on_body, on_complete procs
* [ ] add example to README

### HTTP Headers

* [ ] make Connection#default_headers configurable
* [ ] allow to set default_headers via ENV vars
* [ ] give example how to use default_headers (e.g. request_id)
* [ ] explain in README how to benefit from this gem in a given setting

### ~~Caching~~

* [x] ~~optional per connection or call~~
* [x] ~~add example to README~~

### ~~Timeout~~

* [x] ~~allow to set custom timeout per connection~~
* [x] ~~allow to set custom timeout per call~~
* [x] ~~add (example) to README~~

### ~~Release~~

* [x] ~~rename module to have unique namespace~~
* [x] ~~release to rubygems to add to the plethora of similar gems~~
* [x] ~~make repo public~~
* [x] ~~hook up Travis-CI~~
* [x] ~~ensure it runs with Ruby 2.4 and newer~~

### Retry Requests

* [ ] either leverage Hydra to retry failed calls
  * [ ] configure number of retries
  * [ ] configure delay between retries
  * [ ] retry idempotent calls GET, PUT, DELETE, HEAD automatically
* [ ] maybe implement retries with wait and Redis (external dependency!)
* [ ] or document in README how to build a retry mechanism
  * [ ] https://gist.github.com/kunalmodi/2939288

### Queueing / run requests serialized

* [ ] allow to queue multiple requests
* [ ] execute (up to 5) queued requests
* [ ] allow to pass a on_handler proc (per request) that could involve queueing new requests
* [ ] or just explain how to code that yourself?
* [ ] add example to README

### Rate limiting

* [ ] implement with different strategies
  * [ ] max concurrent requests
  * [ ] max requests in fixed time frame
  * [ ] max requests in sliding time window
* [ ] implement counters in Redis (external dependency!)
* [ ] add metrics / monitoring
* [ ] don't add throttling?
* [ ] add example to README
