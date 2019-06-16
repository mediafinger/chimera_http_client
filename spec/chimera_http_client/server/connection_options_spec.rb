require "server_spec_helper"

describe ChimeraHttpClient::Connection do
  let(:connection)    { described_class.new(base_url: base_url) }
  let(:base_url)      { "#{UsersServer.endpoint_url}/api/v1" }
  let(:endpoint)      { "users/22" }

  let(:frozen_time) { Time.now.utc.iso8601(3) }

  # TODO: test with cache, deserializer, logger, monitor, timeout, ...
  # basic auth https://gist.github.com/nakajima/16483?

  # TIMEOUT
  describe "option timeout" do
    subject(:custom_timeout) { connection.get(endpoint, timeout: 7) }

    it "overrides the default timeout" do
      expect(custom_timeout.response.request.original_options).to include(timeout: 7)
    end
  end

  # MONITOR
  describe "option monitor" do
    let(:connection) { described_class.new(base_url: base_url, monitor: monitor) }

    # monitor that prints out every element separately to STDOUT
    # here in the test we need to manipulate the dynamic times to get a testable result
    let(:monitor) do
      proc do |hash|
        hash.each do |k, v|
          if k == :runtime
            puts("#{k}: 0.015")
          elsif k == :completed_at
            puts("#{k}: #{frozen_time}")
          else
            puts("#{k}: #{v}")
          end
        end
      end
    end

    # GET
    describe "#get!" do
      subject(:get) { connection.get(endpoint, monitoring_context: monitoring_context) }

      let(:monitoring_context) { { user_id: 90210 } }

      it "records request and custom context information" do
        expect { get }.to output(
          "url: #{base_url}/users/22\n"\
          "method: get\n"\
          "status: 200\n"\
          "runtime: 0.015\n"\
          "completed_at: #{frozen_time}\n"\
          "context: {:user_id=>90210}\n"
        ).to_stdout
      end
    end
  end
end
