# HttpClient TODOs

## Bugs

* calling `.to_json` once too often in `HttpError.to_json`?
* add regression spec

## Features

### HTTP Headers

* make Connection#default_headers configurable
* allow to set default_headers via ENV vars
* give example how to use default_headers (e.g. request_id)
* explain in README how to benefit from this gem in a given setting

### Logger

* allow to pass a logger
* add logger.info when starting a http call
* add logger.info when finishing a successful http call
* add logger.warn / .error for error cases
* include the total_time of the requests in the log
* add example to README

### Custom Serializer

* allow to pass custom (de)serializer
* use custom serializer in #parsed_body instead of default JSON serializer
* set header for the serializer
* add example to README

### Queueing

* allow to queue multiple calls
* execute (up to 10) calls in parallel
* add example to README

### Caching

* optional per connection or call
* add example to README

### Release

* rename to have a unique namespace
* make repo public
* hook up Travis-CI
* ensure it runs with Ruby 2.3 and newer
* get feedback
* release to rubygems to add to the plethora of similar gems
