module ChimeraHttpClient
  spec = Gem::Specification.find_by_name("chimera_http_client")
  gem_root = spec.gem_dir

  require "json"
  require "typhoeus"

  librbfiles = File.join(gem_root, "lib", "chimera_http_client", "*.rb")
  Dir.glob(librbfiles) { |file| require file; puts "required: #{file}" }
end
