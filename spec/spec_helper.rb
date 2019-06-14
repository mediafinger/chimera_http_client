spec = Gem::Specification.find_by_name("chimera_http_client")
gem_root = spec.gem_dir

require_relative File.join(gem_root, "lib/chimera_http_client.rb")

RSpec.configure do |config|
  config.before do
    Typhoeus::Expectation.clear
  end
end
