require "spec_helper"

# Regression coverage for a bug where Connection settings (cache, user_agent, verbose)
# were written to the process-global Typhoeus::Config instead of being kept per-instance.
# That meant creating a second Connection with different settings silently changed the
# behavior of every other Connection already in the process.
describe ChimeraHttpClient::Connection do
  context "instance isolation" do
    let(:base_url_a) { "http://127.0.0.1:3000/v1" }
    let(:base_url_b) { "http://127.0.0.1:4000/v1" }
    let(:endpoint)   { "dummy" }

    let(:cache_a) { double("cache_a", get: nil, set: nil) } # rubocop:disable RSpec/VerifiedDoubles
    let(:cache_b) { double("cache_b", get: nil, set: nil) } # rubocop:disable RSpec/VerifiedDoubles

    it "does not leak one Connection's user_agent, cache or verbose setting into another" do
      connection_a = described_class.new(base_url: base_url_a, user_agent: "AgentA", cache: cache_a, verbose: true)
      connection_b = described_class.new(base_url: base_url_b, user_agent: "AgentB", cache: cache_b, verbose: false)

      # each stub needs its own Typhoeus::Response instance: Typhoeus mutates response.request
      # when a stub fires, so sharing one instance across stubs would overwrite which request
      # it points to and defeat the isolation check below
      Typhoeus.stub("#{base_url_a}/#{endpoint}").and_return(Typhoeus::Response.new(code: 200, body: "{}", total_time: 0.1))
      Typhoeus.stub("#{base_url_b}/#{endpoint}").and_return(Typhoeus::Response.new(code: 200, body: "{}", total_time: 0.1))

      response_a = connection_a.get(endpoint)
      response_b = connection_b.get(endpoint)

      expect(response_a.response.request.original_options).to include(
        headers: hash_including("User-Agent" => "AgentA"), cache: cache_a, verbose: true
      )
      expect(response_b.response.request.original_options).to include(
        headers: hash_including("User-Agent" => "AgentB"), cache: cache_b, verbose: false
      )
    end

    it "does not write connection settings into the global Typhoeus::Config" do
      described_class.new(base_url: base_url_a, user_agent: "AgentA", cache: cache_a, verbose: true)

      expect(Typhoeus::Config.user_agent).to be_nil
      expect(Typhoeus::Config.cache).to be_nil
      expect(Typhoeus::Config.verbose).to be_nil
      expect(Typhoeus::Config.memoize).to be false
    end
  end
end
