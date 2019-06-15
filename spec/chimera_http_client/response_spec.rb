require "spec_helper"

RSpec.shared_examples "a Response" do
  it { expect(subject.error?).to be false }
  it { expect(subject.response).to eq(typhoeus_response) }

  it { expect(subject.body).to eq(response_json) }
  it { expect(subject.code).to eq(response_code) }
  it { expect(subject.time).to eq(response_time) }

  it { expect(subject.parsed_body).to eq(response_body) }
  it { expect(subject.parsed_body).to be_kind_of(Hash) }
  it { expect(subject.parsed_body["id"]).to eq(42) }
  it { expect(subject.parsed_body["name"]).to eq("Andy") }
end

describe ChimeraHttpClient::Response do
  subject(:response) { described_class.new(typhoeus_response, deserializer: deserializer) }

  let(:typhoeus_response) { Typhoeus::Response.new(code: response_code, body: response_json, total_time: response_time) }
  let(:deserializer) { { response: ::ChimeraHttpClient::Deserializer.json_response } }

  let(:response_code) { 200 }
  let(:response_body) { { "id" => 42, "name" => "Andy" } }
  let(:response_json) { response_body.to_json }
  let(:response_time) { 0.5 }

  it_behaves_like "a Response"

  context "when body is no json" do
    let(:response_json) { "<html>Hello World</html>" }

    it "throws a helpful error" do
      expect { response.parsed_body }.to raise_error(
        ChimeraHttpClient::JsonParserError, /Could not parse body as JSON: #{response_json}, error: *./
      )
    end
  end
end
