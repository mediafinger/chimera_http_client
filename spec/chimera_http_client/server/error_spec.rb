require "server_spec_helper"

RSpec.shared_examples "an Error" do
  it { expect(error.error?).to be true }
  it { expect(error.success?).to be false }
  it { expect(error.code).to eq(failure_code) }
  it { expect(error.class).to eq(described_class) }
  it { expect(error.body).to eq(expected_parsed_body.to_json) }
  it { expect(error.message).to eq(expected_parsed_body.to_json.to_s) }

  it do
    expect(error.to_s).to match(
      "#{described_class} (#{failure_code}) #{expected_parsed_body.to_json}, URL: #{base_url}/errors/#{failure_code}"
    )
  end

  it { expect(JSON.parse(error.to_json)).to be_kind_of(Hash) }
  it { expect(JSON.parse(error.to_json)["code"]).to eq failure_code }
  it { expect(JSON.parse(error.to_json)["error_class"]).to eq(error.class.name) }
  it { expect(JSON.parse(error.to_json)["message"]).to be_truthy }
  it { expect(JSON.parse(error.to_json)["method"]).to eq("get") }
  it { expect(JSON.parse(error.to_json)["url"]).to eq "#{base_url}/errors/#{failure_code}" }

  it { expect(error.parsed_body).to be_kind_of(Hash) }
  it { expect(error.parsed_body).to eq(JSON.parse(expected_parsed_body.to_json)) }
end

context "when http errors happen" do
  subject(:error) { connection.get("errors/#{failure_code}") }

  let(:connection) { ChimeraHttpClient::Connection.new(base_url: base_url, deserializer: deserializer, timeout: timeout) }
  let(:base_url) { "#{UsersServer.endpoint_url}/api/v1" }
  let(:deserializer) { { error: ChimeraHttpClient::Deserializer.json_error } }
  let(:timeout) { 0.2 }

  let(:expected_parsed_body) { { message: "error #{failure_code}" } }

  # TODO: make it conditional if a redirect should be handled as an error or not
  describe ChimeraHttpClient::RedirectionError do
    let(:failure_code) { 302 }
    let(:class_name) { "HttpRedirectionError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::BadRequestError do
    let(:failure_code) { 400 }
    let(:class_name) { "HttpBadRequestError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::UnauthorizedError do
    let(:failure_code) { 401 }
    let(:class_name) { "HttpUnauthorizedError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::PaymentRequiredError do
    let(:failure_code) { 402 }
    let(:class_name) { "HttpPaymentRequiredError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::ForbiddenError do
    let(:failure_code) { 403 }
    let(:class_name) { "HttpForbiddenError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::NotFoundError do
    let(:failure_code) { 404 }
    let(:class_name) { "HttpNotFoundError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::MethodNotAllowedError do
    let(:failure_code) { 405 }
    let(:class_name) { "HttpMethodNotAllowedError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::ResourceConflictError do
    let(:failure_code) { 409 }
    let(:class_name) { "HttpResourceConflictError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::UnprocessableEntityError do
    let(:failure_code) { 422 }
    let(:class_name) { "HttpUnprocessableEntityError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::ClientError do
    let(:failure_code) { 450 }
    let(:class_name) { "ClientError" }

    it_behaves_like "an Error"
  end

  describe ChimeraHttpClient::ServerError do
    let(:failure_code) { 500 }
    let(:class_name) { "HttpServerError" }

    it_behaves_like "an Error"
  end

  # below tests that work slightly different from the others
  describe ChimeraHttpClient::ConnectionError do
    let(:failure_code) { 0 }
    let(:class_name) { "HttpConnectionError" }

    it { expect(error.error?).to be true }
    it { expect(error.code).to eq(failure_code) }
    it { expect(error.class).to eq(described_class) }
    it { expect(error.to_s).to match("#{described_class} (#{failure_code}) , URL: #{base_url}/errors/#{failure_code}") }

    it { expect(JSON.parse(error.to_json)).to be_kind_of(Hash) }
    it { expect(JSON.parse(error.to_json)["code"]).to eq 0 }
    it { expect(JSON.parse(error.to_json)["error_class"]).to eq("ChimeraHttpClient::ConnectionError") }
    it { expect(JSON.parse(error.to_json)["message"]).to be_truthy }
    it { expect(JSON.parse(error.to_json)["method"]).to eq("get") }
    it { expect(JSON.parse(error.to_json)["url"]).to eq "#{base_url}/errors/#{failure_code}" }

    it { expect(error.parsed_body).to be_kind_of(Hash) }
    it { expect(error.parsed_body).to eq({ "non_json_body" => "" }) }
  end

  # the TimeoutError tests pass, but they take longer than the rest of the whole test suite
  # and as they basically only repeat what the other tests test, they are on pending
  pending ChimeraHttpClient::TimeoutError do
    let(:failure_code) { "timeout" }
    let(:class_name) { "HttpTimeoutError" }

    it { expect(error.error?).to be true }
    it { expect(error.code).to eq(0) }
    it { expect(error.class).to eq(ChimeraHttpClient::TimeoutError) }
    it { expect(error.to_s).to match("#{described_class} (0) , URL: #{base_url}/errors/#{failure_code}") }

    it { expect(JSON.parse(error.to_json)).to be_kind_of(Hash) }
    it { expect(JSON.parse(error.to_json)["code"]).to eq 0 }
    it { expect(JSON.parse(error.to_json)["error_class"]).to eq("ChimeraHttpClient::TimeoutError") }
    it { expect(JSON.parse(error.to_json)["message"]).to be_truthy }
    it { expect(JSON.parse(error.to_json)["method"]).to eq("get") }
    it { expect(JSON.parse(error.to_json)["url"]).to eq "#{base_url}/errors/#{failure_code}" }

    it { expect(error.parsed_body).to be_kind_of(Hash) }
    it { expect(error.parsed_body).to eq({ "non_json_body" => "" }) }
  end

  describe ChimeraHttpClient::Error do
    let(:failure_code) { 400 }
    let(:class_name) { "Error" }

    pending "when the failure body is not real JSON" do
      let(:expected_parsed_body) { { "non_json_body" => "" } }
      let(:failure_body) { "" }
    end

    context "when requests are logged" do
      pending "to_s includes request"
      pending "to_json includes request"
    end
  end
end
