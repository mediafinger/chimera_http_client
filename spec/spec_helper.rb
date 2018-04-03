$LOAD_PATH.unshift File.expand_path("lib", __dir__)
require "http_client"

RSpec.configure do |config|
  config.before :each do
    Typhoeus::Expectation.clear
  end
end
