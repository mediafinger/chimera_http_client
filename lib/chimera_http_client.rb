module ChimeraHttpClient
  ROOT_PATH = File.expand_path("..", __dir__)

  require "json"
  require "typhoeus"

  Dir.glob(ROOT_PATH + "/lib/chimera_http_client/*.rb") { |file| require file }
end
