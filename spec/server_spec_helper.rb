require "spec_helper"

require "webmock/rspec"
require "capybara/rspec"
require "capybara_discoball"

spec = Gem::Specification.find_by_name("chimera_http_client")
gem_root = spec.gem_dir
require_relative File.join(gem_root, "spec/support/users_server.rb")

# Raise an error when a HTTP call to an external endpoint is made
WebMock.disable_net_connect!(allow_localhost: true)

# spin up the mock server and set it's URL
Capybara::Discoball.spin(UsersServer) do |server|
  UsersServer.endpoint_url = server.url
  puts "UsersServer available under: #{server.url}"
end

RSpec.configure do |config|
  config.before do
  end

  config.after do
  end
end
