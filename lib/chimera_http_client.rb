module ChimeraHttpClient
  require "json"
  require "typhoeus"
  require "zeitwerk"

  loader = Zeitwerk::Loader.for_gem
  loader.setup
end
