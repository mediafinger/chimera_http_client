# ChimeraHttpClient TODOs

## Bugs

* The connection_specs are testing for a Hash in the body instead for serialized JSON content
* The implementation seems to be buggy, not handling JSON as intended

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

* allow to pass custom serializer
* use custom serializer instead of expecting a JSON (or other) body
* set header for the serializer
* add example to README

### Custom De-serializer

* allow to pass custom deserializer
* use custom deserializer in #parsed_body instead of default JSON parsing
* add example to README

### Queueing

* allow to queue multiple calls
* execute (up to 10) calls in parallel
* add example to README

### Caching

* optional per connection or call
* add example to README

### Release

* make repo public
* hook up Travis-CI
* ensure it runs with Ruby 2.5 and newer
* get feedback
* release to rubygems to add to the plethora of similar gems
