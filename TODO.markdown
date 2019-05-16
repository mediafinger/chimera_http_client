# ChimeraHttpClient TODOs

## Bugs

_none known_

## Features

### Logger

* ~~allow to pass a logger~~
* ~~add logger.info when starting a http call~~
* ~~add logger.info when finishing a successful http call~~
* ~~include the total_time of the requests in the log~~
* ~~add (example) to README~~
* add logger.warn / .error for error cases (?)

### Custom De-serializer

* allow to pass custom deserializer
* use custom deserializer in #parsed_body instead of default JSON parsing
* add example to README

### Queueing / running in parallel

* ~~allow to queue multiple requests~~
* ~~execute (up to 200) requests in parallel~~
* allow to pass one proc / block (for all requests) to use as on_complete handler for each request
* allow to pass one proc / block per requests) to use as on_complete handler
* add example to README

### Custom Serializer

* allow to pass custom serializer
* use custom serializer instead of expecting a JSON (or other) body
* set header for the serializer
* add example to README

### File Uploads

* add example to README

### Streaming response bodies

* enable to pass on_headers, on_body, on_complete procs
* add example to README

### HTTP Headers

* make Connection#default_headers configurable
* allow to set default_headers via ENV vars
* give example how to use default_headers (e.g. request_id)
* explain in README how to benefit from this gem in a given setting

### ~~Caching~~

* ~~optional per connection or call~~
* ~~add example to README~~

### ~~Timeout~~

* ~~allow to set custom timeout per connection~~
* ~~allow to set custom timeout per call~~
* ~~add (example) to README~~

### Release

* ~~rename module to have unique namespace~~
* ~~release to rubygems to add to the plethora of similar gems~~
* ~~make repo public~~
* hook up Travis-CI
* ensure it runs with Ruby 2.4 and newer
* get feedback

### Queueing / run requests serialized

* allow to queue multiple requests
* execute (up to 5) queued requests
* allow to pass a on_handler proc (per request) that could involve queueing new requests
* or just explain how to code that yourself?
* add example to README
