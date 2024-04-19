require "server_spec_helper"

RSpec.shared_examples "a Request" do
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
    subject(:request) { connection.request.run(url: url, method: :get) }

    let(:url) { "#{UsersServer.endpoint_url}/api/v1/errors/#{response_code}" }
    let(:connection) { ChimeraHttpClient::Connection.new(base_url: "", timeout: timeout) }
    let(:timeout) { 0.2 }
    let(:response_body) { { message: "LGTM #{response_code}" } }

    context "success" do # rubocop:disable RSpec/RepeatedExampleGroupBody
      let(:response_code) { 200 }

      it_behaves_like "a Request"
    end

    context "204" do
      let(:response_code) { 204 }

      it_behaves_like "a Request"
    end

    # the TimeoutError tests pass, but they take longer than the rest of the whole test suite
    # and as they basically only repeat what the other tests test, they are usually excluded
    pending "Timeout" do
      let(:url) { "#{UsersServer.endpoint_url}/api/v1/errors/timeout" }
      let(:response_code) { nil }

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

    context "when no logger is provided" do # rubocop:disable RSpec/RepeatedExampleGroupBody
      let(:response_code) { 200 }

      it_behaves_like "a Request"
    end
  end
end
