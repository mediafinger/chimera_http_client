require "spec_helper"

RSpec.shared_examples "a Request (with stubbed response)" do
  it { expect(subject).to be_kind_of(ChimeraHttpClient::Response) }
  it { expect(subject.code).to eq(response_code) }
  it { expect(subject.error?).to be false }
  it { expect { subject }.not_to raise_error }
end

describe ChimeraHttpClient::Request do
  describe "#create" do
    subject(:request) { described_class.new.create(url: "http://example.com", method: :get) }

    it "returns a Typhoeus::Request" do
      expect(request).to be_a(described_class)
    end

    it "does not have a response" do
      expect(request.request.response).to eq(nil)
    end

    it "does have an empty result" do
      expect(request.result).to eq(nil)
    end
  end

  describe "#run" do
    subject(:request) { described_class.new(deserializer: deserializer).run(url: url, method: :get) }

    let(:url) { "http://127.0.0.1/dummy" }
    let(:typhoeus_response) { Typhoeus::Response.new(code: response_code, body: response_json, total_time: response_time) }
    let(:deserializer) { { error: ::ChimeraHttpClient::Deserializer.json_error } }
    let(:response_body) { { "id" => 42, "name" => "Andy" } }
    let(:response_json) { response_body.to_json }
    let(:response_time) { 0.5 }

    before { Typhoeus.stub(url).and_return(typhoeus_response) }

    context "success" do
      let(:response_code) { 200 }

      it_behaves_like "a Request (with stubbed response)"
    end

    context "204" do
      let(:response_code) { 204 }

      it_behaves_like "a Request (with stubbed response)"
    end

    context "Timeout" do
      let(:response_code) { nil }

      before { allow(typhoeus_response).to receive(:timed_out?).and_return(true) }

      it { expect(request).to be_kind_of(ChimeraHttpClient::TimeoutError) }
    end

    context "302" do
      let(:response_code) { 302 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::RedirectionError) }
    end

    context "400" do
      let(:response_code) { 400 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::BadRequestError) }
    end

    context "401" do
      let(:response_code) { 401 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::UnauthorizedError) }
    end

    context "403" do
      let(:response_code) { 403 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::ForbiddenError) }
    end

    context "404" do
      let(:response_code) { 404 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::NotFoundError) }
    end

    context "405" do
      let(:response_code) { 405 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::MethodNotAllowedError) }
    end

    context "409" do
      let(:response_code) { 409 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::ResourceConflictError) }
    end

    context "422" do
      let(:response_code) { 422 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::UnprocessableEntityError) }
    end

    context "450" do
      let(:response_code) { 450 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::ClientError) }
    end

    context "500" do
      let(:response_code) { 500 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::ServerError) }
    end

    context "0" do
      let(:response_code) { 0 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::ConnectionError) }
    end

    context "when no logger is provided" do
      subject(:request) { described_class.new(deserializer: deserializer).run(url: url, method: :get) }

      let(:response_code) { 200 }

      it_behaves_like "a Request (with stubbed response)"
    end
  end
end
