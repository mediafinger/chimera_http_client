lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "http_client/version"

Gem::Specification.new do |spec|
  spec.name          = "http-client"
  spec.version       = HttpClient::VERSION
  spec.authors       = ["Andreas Finger"]
  spec.email         = ["andy@mediafinger.com"]

  spec.summary       = "Http Client to connect to REST APIs"
  spec.description   = "General http-client functionality to easily connect to JSON endpoints"
  spec.homepage      = "https://github.com/mediafinger/http-client"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "typhoeus", "~> 1.1"

  spec.add_development_dependency "bundler",       "~> 1.13"
  spec.add_development_dependency "rake",          ">= 10.0"
  spec.add_development_dependency "rspec",         "~> 3.0"
  spec.add_development_dependency "rubocop",       "~> 0.50"
  spec.add_development_dependency "rubocop-rspec", "~> 1.4"
end
