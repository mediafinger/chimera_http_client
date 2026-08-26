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
      expect(request.request.response).to be_nil
    end

    it "does have an empty result" do
      expect(request.result).to be_nil
    end
  end

  describe "#run" do
    subject(:request) { described_class.new(deserializer: deserializer).run(url: url, method: :get) }

    let(:url) { "http://127.0.0.1/dummy" }
    let(:typhoeus_response) { Typhoeus::Response.new(code: response_code, body: response_json, total_time: response_time) }
    let(:deserializer) { { error: ChimeraHttpClient::Deserializer.json_error } }
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

    context "402" do
      let(:response_code) { 402 }

      it { expect(request).to be_kind_of(ChimeraHttpClient::PaymentRequiredError) }
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

  describe "#run with retries" do
    subject(:result) { request_instance.run(url: url, method: method, options: options) }

    let(:request_instance) { described_class.new(deserializer: deserializer) }
    let(:deserializer) { { error: ChimeraHttpClient::Deserializer.json_error } }
    let(:url)     { "http://127.0.0.1/dummy" }
    let(:method)  { :get }
    let(:options) { { retries: retries, retry_delay: retry_delay } }
    let(:retries) { 2 }
    let(:retry_delay) { 1 }

    let(:server_error_response) { Typhoeus::Response.new(code: 500, body: "boom", total_time: 0.1) }
    let(:not_found_response)    { Typhoeus::Response.new(code: 404, body: "nope", total_time: 0.1) }
    let(:success_response)      { Typhoeus::Response.new(code: 200, body: { "id" => 1 }.to_json, total_time: 0.1) }

    before { allow(request_instance).to receive(:sleep) }

    context "when it fails with a retryable error and then succeeds" do
      before { Typhoeus.stub(url).and_return([server_error_response, server_error_response, success_response]) }

      it "returns the eventual successful response" do
        expect(result).to be_a(ChimeraHttpClient::Response)
        expect(result.code).to eq(200)
      end

      it "waits with the fixed 2x backoff before each retry, in order" do
        result

        expect(request_instance).to have_received(:sleep).with(1).ordered
        expect(request_instance).to have_received(:sleep).with(2).ordered
      end
    end

    context "when every attempt fails" do
      before { Typhoeus.stub(url).and_return(server_error_response) }

      it "returns the last error once retries are exhausted" do
        expect(result).to be_a(ChimeraHttpClient::ServerError)
      end

      it "sleeps exactly `retries` times" do
        result

        expect(request_instance).to have_received(:sleep).twice
      end
    end

    context "when retries is not configured (defaults to 0)" do
      let(:options) { {} }

      before { Typhoeus.stub(url).and_return(server_error_response) }

      it "does not retry" do
        expect(result).to be_a(ChimeraHttpClient::ServerError)
        expect(request_instance).not_to have_received(:sleep)
      end
    end

    context "when the error is not retryable (e.g. 404)" do
      before { Typhoeus.stub(url).and_return(not_found_response) }

      it "does not retry" do
        expect(result).to be_a(ChimeraHttpClient::NotFoundError)
        expect(request_instance).not_to have_received(:sleep)
      end
    end

    context "when the method is not idempotent (e.g. post)" do
      let(:method) { :post }

      before { Typhoeus.stub(url).and_return(server_error_response) }

      it "does not retry even though the error is retryable" do
        expect(result).to be_a(ChimeraHttpClient::ServerError)
        expect(request_instance).not_to have_received(:sleep)
      end
    end
  end
end
