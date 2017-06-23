module HttpClient
  ROOT_PATH = File.expand_path('../..', __FILE__)

  require 'json'
  require 'typhoeus'

  Dir.glob(ROOT_PATH + '/lib/http_client/*.rb') { |file| require file }
end
