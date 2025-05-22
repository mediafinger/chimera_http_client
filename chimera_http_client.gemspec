lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chimera_http_client/version"

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 2.7.0" # probably 2.5.0 still works, but 2.7 is the oldest tested version

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
    caching requests individiually, and instrumentation support (soon to be implemented).
  DESCRIPTION

  spec.homepage      = "https://github.com/mediafinger/chimera_http_client"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["rubygems_mfa_required"] = "true"

  # the only sub-dependencies
  spec.add_dependency "typhoeus", "~> 1.4"
  spec.add_dependency "zeitwerk", ">= 2.6"

  # general development and test dependencies
  spec.add_development_dependency "amazing_print",      ">= 1.8"
  spec.add_development_dependency "bundler",            ">= 2.2"
  spec.add_development_dependency "bundler-audit",      ">= 0.9"
  spec.add_development_dependency "irb",                ">= 1.15"
  spec.add_development_dependency "rake",               ">= 13.2"
  spec.add_development_dependency "rspec",              "~> 3.13"
  spec.add_development_dependency "rubocop",            "~> 1.75.7"
  spec.add_development_dependency "rubocop-rake",       "~> 0.7.1"
  spec.add_development_dependency "rubocop-rspec",      "~> 3.6.0"

  # only for server specs with real HTTP requests
  spec.add_development_dependency "capybara",           "~> 3.40"
  spec.add_development_dependency "capybara_discoball", "~> 0.1"
  spec.add_development_dependency "rackup",             "~> 2.2"
  spec.add_development_dependency "sinatra",            "~> 4.1"
  spec.add_development_dependency "sinatra-contrib",    "~> 4.1"
  spec.add_development_dependency "webmock",            "~> 3.25"
  spec.add_development_dependency "webrick",            "~> 1.9"
end
