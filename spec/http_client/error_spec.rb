require "spec_helper"

context "http errors" do
  subject(:api_error) { described_class.new(typhoeus_response) }

  let(:base_url) { "https://domain/path" }
  let(:method) { :patch }
  let(:typhoeus_response) do
    Typhoeus::Response.new(code: failure_code, body: failure_body, total_time: response_time)
                      .tap { |resp| resp.request = Typhoeus::Request.new(base_url, method: method) }
  end
  let(:expected_parsed_body) { { "errors" => [{ "code" => failure_code }] } }
  let(:failure_body) { expected_parsed_body.to_json }
  let(:response_time) { 0.5 }

  RSpec.shared_examples "a HttpError" do
    it { expect(subject.error?).to be true }
    it { expect(subject.code).to eq(failure_code) }
    it { expect(subject.body).to eq(failure_body) }
    it { expect(subject.message).to eq(failure_body) }
    it { expect(subject.time).to eq(response_time) }

    it { expect(subject.to_s).to match("#{subject.class.name} (#{failure_code}) #{failure_body}, URL: #{base_url}") }

    it { expect(JSON.parse(subject.to_json)).to be_kind_of(Hash) }
    it { expect(JSON.parse(subject.to_json)["code"]).to eq failure_code }
    it { expect(JSON.parse(subject.to_json)["error_class"]).to eq(subject.class.name) }
    it { expect(JSON.parse(subject.to_json)["message"]).to be_truthy }
    it { expect(JSON.parse(subject.to_json)["method"]).to eq method.to_s }
    it { expect(JSON.parse(subject.to_json)["url"]).to eq base_url }

    it { expect(subject.response).to eq(typhoeus_response) }

    it { expect(subject.parsed_body).to be_kind_of(Hash) }
    it { expect(subject.parsed_body).to eq(expected_parsed_body) }
  end

  describe HttpClient::HttpError do
    let(:failure_code) { 400 }
    let(:class_name) { "HttpError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpConnectionError do
    let(:failure_code) { 0 }
    let(:class_name) { "HttpConnectionError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpRedirectionError do
    let(:failure_code) { 302 }
    let(:class_name) { "HttpRedirectionError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpBadRequestError do
    let(:failure_code) { 400 }
    let(:class_name) { "HttpBadRequestError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpUnauthorizedError do
    let(:failure_code) { 401 }
    let(:class_name) { "HttpUnauthorizedError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpForbiddenError do
    let(:failure_code) { 403 }
    let(:class_name) { "HttpForbiddenError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpNotFoundError do
    let(:failure_code) { 404 }
    let(:class_name) { "HttpNotFoundError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpMethodNotAllowedError do
    let(:failure_code) { 405 }
    let(:class_name) { "HttpMethodNotAllowedError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpResourceConflictError do
    let(:failure_code) { 409 }
    let(:class_name) { "HttpResourceConflictError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpUnprocessableEntityError do
    let(:failure_code) { 422 }
    let(:class_name) { "HttpUnprocessableEntityError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpClientError do
    let(:failure_code) { 450 }
    let(:class_name) { "HttpClientError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpServerError do
    let(:failure_code) { 500 }
    let(:class_name) { "HttpServerError" }

    it_behaves_like "a HttpError"
  end

  describe HttpClient::HttpTimeoutError do
    let(:failure_code) { 0 }
    let(:class_name) { "HttpTimeoutError" }

    it_behaves_like "a HttpError"

    context "when the failure body is not real JSON" do
      let(:expected_parsed_body)      { { "non_json_body" => "" } }
      let(:failure_body) { "" }

      it_behaves_like "a HttpError"
    end

    context "when requests are logged" do
      pending "to_s includes request"
      pending "to_json includes request"
    end
  end
end
