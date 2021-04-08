require "spec_helper"

describe ChimeraHttpClient::Queue do # rubocop:disable RSpec/FilePath
  let(:queue) { described_class.new(base_url: base_url) }
  let(:base_url) { "http://127.0.0.1:3000/v1" }

  let(:method)       { "GET" }
  let(:endpoint)     { "dummy" }
  let(:bad_endpoint) { "failure" }

  let(:typhoeus_response) { Typhoeus::Response.new(code: response_code, body: response_json, total_time: response_time) }
  let(:response_code) { 200 }
  let(:response_body) { { "id" => 42, "name" => "Andy" } }
  let(:response_json) { response_body.to_json }
  let(:response_time) { 0.5 }

  let(:failure_response) { Typhoeus::Response.new(code: failure_code, body: failure_body, total_time: response_time) }
  let(:failure_code) { 404 }
  let(:failure_body) { "#{failure_code} not_found" }

  describe "#add" do
    it { expect(queue).to be_a(described_class) }
    it { expect(queue.add(method, endpoint)).to be_a(Array) }
    it { expect(queue.add(method, endpoint).first).to be_a(ChimeraHttpClient::Request) }
  end

  describe "#execute" do
    before do
      Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response)
      Typhoeus.stub("#{base_url}/#{bad_endpoint}").and_return(failure_response)
    end

    it "runs all queued requests", :aggregated_failures do
      queue.add(method, endpoint)
      queue.add(method, bad_endpoint)

      responses = queue.execute

      expect(responses).to be_a(Array)
      expect(responses.count).to eq(2)

      expect(responses.first).to be_a(ChimeraHttpClient::Response)
      expect(responses.first.code).to eq(200)
      expect(responses.first.parsed_body).to eq(response_body)

      expect(responses.last).to be_a(ChimeraHttpClient::Error)
      expect(responses.last.code).to eq(404)
      expect(responses.last.parsed_body).to eq({ "non_json_body" => failure_body })
    end
  end

  describe "#empty" do
    it "deletes queued requests" do
      queue.add(method, endpoint)

      expect(queue.empty).to eq([])
    end
  end
end
