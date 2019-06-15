require "server_spec_helper"

describe ChimeraHttpClient::Queue do
  let(:queue) { described_class.new(base_url: base_url) }
  let(:base_url) { "#{UsersServer.endpoint_url}/api/v1" }

  let(:method)       { "GET" }
  let(:endpoint)     { "users/4444" }
  let(:bad_endpoint) { "users/404" }

  describe "#add" do
    it { expect(queue).to be_a(described_class) }
    it { expect(queue.add(method, endpoint)).to be_a(Array) }
    it { expect(queue.add(method, endpoint).first).to be_a(ChimeraHttpClient::Request) }
  end

  describe "#execute" do
    it "runs all queued requests", :aggregated_failures do
      queue.add(method, endpoint)
      queue.add(method, bad_endpoint)

      responses = queue.execute

      expect(responses).to be_a(Array)
      expect(responses.count).to eq(2)

      expect(responses.first).to be_a(ChimeraHttpClient::Response)
      expect(responses.first.code).to eq(200)
      expect(responses.first.parsed_body).to eq(
        {
          "email" => "melisandre@example.com",
          "id" => "4444",
          "name" => "The Red Woman",
        }
      )

      expect(responses.last).to be_a(ChimeraHttpClient::Error)
      expect(responses.last.code).to eq(404)
      expect(responses.last.parsed_body).to eq({ "message" => "User with id = 404 not found" })
    end
  end

  describe "#empty" do
    it "deletes queued requests" do
      queue.add(method, endpoint)

      expect(queue.empty).to eq([])
    end
  end
end
