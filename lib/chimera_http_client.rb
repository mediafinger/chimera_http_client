module ChimeraHttpClient
  require "json"
  require "typhoeus"
  require "zeitwerk"

  loader = Zeitwerk::Loader.for_gem
  loader.setup

  # as Zeitwerk can't handle innner classes properly :-/
  require_relative "chimera_http_client/error"
end
