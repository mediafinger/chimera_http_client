require "server_spec_helper"

RSpec.shared_examples "a Response" do
  it { expect(subject.error?).to be false }
  it { expect(subject.class).to eq(ChimeraHttpClient::Response) }

  it { expect(subject.body).to eq(response_body.to_json) }
  it { expect(subject.code).to eq(response_code) }
  it { expect(subject.time).to be_a(Float) }

  it { expect(subject.parsed_body).to eq(response_body) }
  it { expect(subject.parsed_body).to be_kind_of(Hash) }
  it { expect(subject.parsed_body["id"]).to eq("1") }
  it { expect(subject.parsed_body["name"]).to eq("Arya Stark") }
end

describe ChimeraHttpClient::Response do
  subject(:response) { connection.get(endpoint) }

  let(:connection) { ChimeraHttpClient::Connection.new(base_url: base_url, deserializer: deserializer, timeout: timeout) }
  let(:base_url) { "#{UsersServer.endpoint_url}/api/v1" }
  let(:deserializer) { { response: ::ChimeraHttpClient::Deserializer.json_response } }
  let(:timeout) { 0.2 }

  let(:response_code) { 200 }
  let(:response_body) { { "id" => "1", "email" => "no_one@example.com", "name" => "Arya Stark" } }

  context "when response is successful" do
    let(:endpoint) { "users/1" }

    it_behaves_like "a Response"
  end

  context "when body is no json" do
    subject(:response) { connection.get(endpoint) }

    let(:endpoint) { "html" }
    let(:base_url) { UsersServer.endpoint_url }
    let(:response_body) { "<html><body>Hello :-)</body></html>" }

    it { expect(response.class).to eq(described_class) }
    it { expect(response.body).to eq(response_body) }
    it "throws a helpful error" do
      expect { response.parsed_body }.to raise_error(
        ChimeraHttpClient::JsonParserError, /Could not parse body as JSON *./
      )
    end
  end
end
