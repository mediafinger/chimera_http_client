lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chimera_http_client/version"

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 2.5.0" # without Deserializer's `rescue` in block it would be 2.4.4 (because of zeitwerk)

  spec.name          = "chimera_http_client"
  spec.version       = ChimeraHttpClient::VERSION
  spec.authors       = ["Andreas Finger"]
  spec.email         = ["webmaster@mediafinger.com"]

  spec.summary       = "General http client functionality to quickly connect to JSON REST API endpoints and any others"
  spec.description   = <<~DESCRIPTION
    The Chimera http client offers an easy to learn interface and consistent error handling.
    It is lightweight, fast and enables you to queue HTTP requests to run them in parallel
    for better performance and simple aggregating of distributed data. Despite it's simple
    interface it allows for advanced features like using custom deserializers, loggers,
    caching requests individiually, and custom instrumentation support.
  DESCRIPTION

  spec.homepage      = "https://github.com/mediafinger/chimera_http_client"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # the only sub-dependencies
  spec.add_runtime_dependency "typhoeus", "~> 1.1"
  spec.add_runtime_dependency "zeitwerk", ">= 2.0"

  # general development and test dependencies
  spec.add_development_dependency "awesome_print",      "~> 1.8"
  spec.add_development_dependency "bundler",            ">= 1.0"
  spec.add_development_dependency "bundler-audit",      "~> 0.6"
  spec.add_development_dependency "irb",                "~> 1.0"
  spec.add_development_dependency "rake",               ">= 10.0"
  spec.add_development_dependency "rspec",              "~> 3.0"
  spec.add_development_dependency "rubocop",            "~> 0.50"
  spec.add_development_dependency "rubocop-rspec",      "~> 1.4"

  # only for server specs with real HTTP requests
  spec.add_development_dependency "capybara",           "~> 3.0"
  spec.add_development_dependency "capybara_discoball", "~> 0.1"
  spec.add_development_dependency "sinatra",            "~> 2.0"
  spec.add_development_dependency "sinatra-contrib",    "~> 2.0"
  spec.add_development_dependency "webmock",            "~> 3.0"
end
