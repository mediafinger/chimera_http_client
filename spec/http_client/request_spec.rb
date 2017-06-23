require "spec_helper"

RSpec.shared_examples "a Request" do
  it { expect(subject).to be_kind_of(HttpClient::Response) }
  it { expect(subject.code).to eq(response_code) }
  it { expect(subject.error?).to be false }
  it { expect { subject }.not_to raise_error }
end

describe HttpClient::Request do
  subject(:request) { described_class.new.run(url: url, method: :get) }

  let(:url) { "http://127.0.0.1/dummy" }
  let(:typhoeus_response) { Typhoeus::Response.new(code: response_code, body: response_json, total_time: response_time) }
  let(:response_body) { { "id" => 42, "name" => "Andy" } }
  let(:response_json) { response_body.to_json }
  let(:response_time) { 0.5 }

  before { Typhoeus.stub(url).and_return(typhoeus_response) }

  context "success" do
    let(:response_code) { 200 }

    it_behaves_like "a Request"
  end

  context "204" do
    let(:response_code) { 204 }
    it_behaves_like "a Request"
  end

  context "Timeout" do
    let(:response_code) { nil }

    before { allow(typhoeus_response).to receive(:timed_out?).and_return(true) }

    it { expect(request).to be_kind_of(HttpClient::HttpTimeoutError) }
  end

  context "302" do
    let(:response_code) { 302 }
    it { expect(request).to be_kind_of(HttpClient::HttpRedirectionError) }
  end

  context "400" do
    let(:response_code) { 400 }
    it { expect(request).to be_kind_of(HttpClient::HttpBadRequestError) }
  end

  context "401" do
    let(:response_code) { 401 }
    it { expect(request).to be_kind_of(HttpClient::HttpUnauthorizedError) }
  end

  context "403" do
    let(:response_code) { 403 }
    it { expect(request).to be_kind_of(HttpClient::HttpForbiddenError) }
  end

  context "404" do
    let(:response_code) { 404 }
    it { expect(request).to be_kind_of(HttpClient::HttpNotFoundError) }
  end

  context "405" do
    let(:response_code) { 405 }
    it { expect(request).to be_kind_of(HttpClient::HttpMethodNotAllowedError) }
  end

  context "409" do
    let(:response_code) { 409 }
    it { expect(request).to be_kind_of(HttpClient::HttpResourceConflictError) }
  end

  context "422" do
    let(:response_code) { 422 }
    it { expect(request).to be_kind_of(HttpClient::HttpUnprocessableEntityError) }
  end

  context "450" do
    let(:response_code) { 450 }
    it { expect(request).to be_kind_of(HttpClient::HttpClientError) }
  end

  context "500" do
    let(:response_code) { 500 }
    it { expect(request).to be_kind_of(HttpClient::HttpServerError) }
  end

  context "0" do
    let(:response_code) { 0 }
    it { expect(request).to be_kind_of(HttpClient::HttpConnectionError) }
  end

  context "when no logger is provided" do
    subject(:request) { described_class.new.run(url: url, method: :get) }
    let(:response_code) { 200 }

    it_behaves_like "a Request"
  end
end
