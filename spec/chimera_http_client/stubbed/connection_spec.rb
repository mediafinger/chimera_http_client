require "spec_helper"

RSpec.shared_examples "a Connection call that is successful (with stubbed response)" do
  it { expect(subject).to be_kind_of(ChimeraHttpClient::Response) }

  it { expect(subject.code).to eq(response_code) }
  it { expect(subject.body).to eq(response_json) }
  it { expect(subject.time).to eq(response_time) }
  it { expect(subject.response).to eq(typhoeus_response) }

  it { expect(subject.parsed_body).to eq(response_body) }
  it { expect(subject.error?).to be false }

  it { expect { subject }.not_to raise_error }
end

RSpec.shared_examples "a Connection call that returns an error (with stubbed response)" do
  it { expect(subject).to be_kind_of(ChimeraHttpClient::Error) }

  it { expect(subject.error?).to be true }
  it { expect(subject.code).to eq(failure_code) }
  it { expect(subject.body).to eq(failure_body) }
  it { expect(subject.message).to eq(failure_body) }
  it { expect(subject.time).to eq(response_time) }
end

RSpec.shared_examples "a Connection call that raises an error (with stubbed response)" do
  it "raises an error" do
    expect { subject }.to raise_error(ChimeraHttpClient::Error)
  end
end

RSpec.shared_examples "a Connection request with correct headers (with stubbed response)" do
  it "sets the expected headers" do
    expect(subject.response.request.original_options).to eq(
      {
        method:          method,
        body:            body,
        params:          params,
        headers:         headers,
        timeout:         ChimeraHttpClient::Request::TIMEOUT_SECONDS,
        accept_encoding: "gzip",
        cache:           nil,
        verbose:         false,
      }
    )
  end
end

describe ChimeraHttpClient::Connection do
  let(:connection) { described_class.new(base_url: base_url) }
  let(:base_url) { "http://127.0.0.1:3000/v1" }

  let(:typhoeus_response) { Typhoeus::Response.new(code: response_code, body: response_json, total_time: response_time) }
  let(:endpoint)      { "dummy" }
  let(:response_code) { 200 }
  let(:response_body) { { "id" => 42, "name" => "Andy" } }
  let(:response_json) { response_body.to_json }
  let(:response_time) { 0.5 }

  let(:failure_response) { Typhoeus::Response.new(code: failure_code, body: failure_body, total_time: response_time) }
  let(:failure_code) { 400 }
  let(:failure_body) { "#{failure_code} BadRequest" }

  let(:context) { double("context") } # rubocop:disable RSpec/VerifiedDoubles
  let(:request_headers) { { "Content-Type" => "application/json", "User-Agent" => ChimeraHttpClient::Base::USER_AGENT } }

  describe ".new (ensure methods are generated correctly)" do
    it { expect(connection).to be_kind_of described_class }

    it { expect(connection).to respond_to(:request) }
    it { expect(connection).to respond_to(:get) }
    it { expect(connection).to respond_to(:post) }
    it { expect(connection).to respond_to(:put) }
    it { expect(connection).to respond_to(:patch) }
    it { expect(connection).to respond_to(:delete) }
    it { expect(connection).to respond_to(:head) }
    it { expect(connection).to respond_to(:options) }
    it { expect(connection).to respond_to(:trace) }
    it { expect(connection).to respond_to(:get!) }
    it { expect(connection).to respond_to(:post!) }
    it { expect(connection).to respond_to(:put!) }
    it { expect(connection).to respond_to(:patch!) }
    it { expect(connection).to respond_to(:delete!) }
    it { expect(connection).to respond_to(:head!) }
    it { expect(connection).to respond_to(:options!) }
    it { expect(connection).to respond_to(:trace!) }

    it { expect(connection.request).to be_kind_of ChimeraHttpClient::Request }
  end

  # OPTIONS
  describe "option timeout" do
    subject(:custom_timeout) { connection.get(endpoint, timeout: 12) }

    it "overrides the default timeout" do
      expect(custom_timeout.response.request.original_options).to include(timeout: 12)
    end
  end

  describe "option headers" do
    subject(:custom_headers) { connection.get(endpoint, headers: { "X-Custom" => "yes" }) }

    before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

    it "merges a per-request header on top of the connection's default headers" do
      expect(custom_headers.response.request.original_options[:headers]).to include(
        "Content-Type" => "application/json", "User-Agent" => ChimeraHttpClient::Base::USER_AGENT, "X-Custom" => "yes"
      )
    end
  end

  describe "connection-level default headers" do
    let(:custom_connection) do
      described_class.new(base_url: base_url, headers: { "Content-Type" => "application/xml" })
    end

    before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

    it "overrides just the given key, keeping everything else (e.g. User-Agent)" do
      response = custom_connection.get(endpoint)

      expect(response.response.request.original_options[:headers]).to eq(
        "Content-Type" => "application/xml", "User-Agent" => ChimeraHttpClient::Base::USER_AGENT
      )
    end

    it "still lets a per-request header override the connection-level default" do
      response = custom_connection.get(endpoint, headers: { "Content-Type" => "text/plain" })

      expect(response.response.request.original_options[:headers]).to include("Content-Type" => "text/plain")
    end
  end

  describe "default headers via ENV", :aggregated_failures do
    let(:plain_connection) { described_class.new(base_url: base_url) }

    before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

    around do |example|
      original = ENV.fetch("CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS", nil)
      example.run
      ENV["CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS"] = original
    end

    it "merges a header from the ENV var into every request" do
      ENV["CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS"] = '{"X-Service-Name":"orders-api"}'

      response = plain_connection.get(endpoint)

      expect(response.response.request.original_options[:headers]).to include("X-Service-Name" => "orders-api")
    end

    it "lets a connection-level header override the same key from ENV" do
      ENV["CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS"] = '{"Content-Type":"text/xml"}'
      connection_with_override = described_class.new(base_url: base_url, headers: { "Content-Type" => "application/json" })

      response = connection_with_override.get(endpoint)

      expect(response.response.request.original_options[:headers]).to include("Content-Type" => "application/json")
    end

    it "raises a clear error for malformed JSON" do
      ENV["CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS"] = "{not valid json"

      expect do
        plain_connection
      end.to raise_error(ChimeraHttpClient::ParameterMissingError, /CHIMERA_HTTP_CLIENT_DEFAULT_HEADERS/)
    end
  end

  describe "ChimeraHttpClient::Base::DEFAULT_HEADERS" do
    it { expect(ChimeraHttpClient::Base::DEFAULT_HEADERS).to eq("Content-Type" => "application/json") }
    it { expect(ChimeraHttpClient::Base::DEFAULT_HEADERS).to be_frozen }
  end

  describe "body serialization" do
    before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

    context "with a Hash body" do
      it "auto-serializes it to JSON by default" do
        response = connection.post(endpoint, body: { "name" => "Andy" })

        expect(response.response.request.original_options[:body]).to eq({ "name" => "Andy" }.to_json)
      end
    end

    context "with an Array body" do
      it "auto-serializes it to JSON by default" do
        response = connection.post(endpoint, body: [1, 2, 3])

        expect(response.response.request.original_options[:body]).to eq([1, 2, 3].to_json)
      end
    end

    context "with an already-serialized String body" do
      it "passes it through completely unchanged (no double-encoding)" do
        already_serialized = { "name" => "Andy" }.to_json

        response = connection.post(endpoint, body: already_serialized)

        expect(response.response.request.original_options[:body]).to equal(already_serialized)
      end
    end

    context "without a body, and not optional" do
      it "still raises ParameterMissingError" do
        expect { connection.post(endpoint) }.to raise_error(ChimeraHttpClient::ParameterMissingError)
      end
    end

    context "with a connection-level custom serializer" do
      let(:custom_serializer) { ->(body) { body.map { |k, v| "#{k}=#{v}" }.join("&") } }
      let(:custom_connection) { described_class.new(base_url: base_url, serializer: custom_serializer) }

      it "uses the custom serializer instead of the default" do
        response = custom_connection.post(endpoint, body: { "name" => "Andy" })

        expect(response.response.request.original_options[:body]).to eq("name=Andy")
      end
    end

    context "with a per-request serializer override" do
      let(:custom_serializer) { ->(body) { body.map { |k, v| "#{k}=#{v}" }.join("&") } }

      it "uses the per-request serializer instead of the connection-level default" do
        response = connection.post(endpoint, body: { "name" => "Andy" }, serializer: custom_serializer)

        expect(response.response.request.original_options[:body]).to eq("name=Andy")
      end
    end

    context "with an no-op serializer that conserves the body as is" do
      it "leaves a Hash body unconverted, so Typhoeus/Ethon can form-encode it natively" do
        response = connection.post(endpoint, body: { "name" => "Andy" }, serializer: ->(body) { body })

        expect(response.response.request.original_options[:body]).to eq("name" => "Andy")
      end
    end
  end

  # GET
  describe "#get" do
    subject(:get) { connection.get(endpoint, context: context) }

    let(:method)  { :get }
    let(:params)  { {} }
    let(:body)    { nil }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that returns an error (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end
  end

  describe "#get!" do
    subject(:get!) { connection.get!(endpoint, context: context) }

    let(:method)  { :get }
    let(:params)  { {} }
    let(:body)    { nil }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that raises an error (with stubbed response)"
    end
  end

  # POST
  describe "#post" do
    subject(:post) { connection.post(endpoint, body: body, context: context) }

    let(:method)  { :post }
    let(:body)    { response_json }
    let(:params)  { {} }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that returns an error (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end

    context "missing body" do
      let(:body) { nil }

      it "raises an error" do
        expect { post }.to raise_error(ChimeraHttpClient::ParameterMissingError)
      end
    end
  end

  describe "#post!" do
    subject(:post!) { connection.post!(endpoint, body: body, context: context) }

    let(:method)  { :post }
    let(:params)  { {} }
    let(:body)    { response_json }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that raises an error (with stubbed response)"
    end

    context "missing body" do
      let(:body) { nil }

      it "raises an error" do
        expect { post! }.to raise_error(ChimeraHttpClient::ParameterMissingError)
      end
    end
  end

  # delete
  describe "#delete" do
    subject(:delete) { connection.delete(endpoint, body: body, context: context) }

    let(:method)  { :delete }
    let(:params)  { {} }
    let(:body)    { nil }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"

      context "with body" do
        let(:body) { { number: "+493012345678" }.to_json }

        before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

        it_behaves_like "a Connection call that is successful (with stubbed response)"
        it_behaves_like "a Connection request with correct headers (with stubbed response)"
      end
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that returns an error (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end
  end

  describe "#delete!" do
    subject(:delete!) { connection.delete!(endpoint, body: body, context: context) }

    let(:method)  { :delete }
    let(:params)  { {} }
    let(:body)    { nil }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"

      context "with body" do
        let(:body) { { number: "+493012345678" }.to_json }

        before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

        it_behaves_like "a Connection call that is successful (with stubbed response)"
        it_behaves_like "a Connection request with correct headers (with stubbed response)"
      end
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that raises an error (with stubbed response)"
    end
  end

  # PUT
  describe "#put" do
    subject(:put) { connection.put(endpoint, body: body, context: context) }

    let(:method)  { :put }
    let(:params)  { {} }
    let(:body)    { response_json }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that returns an error (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end
  end

  describe "#put!" do
    subject(:put!) { connection.put!(endpoint, body: body, context: context) }

    let(:method)  { :put }
    let(:params)  { {} }
    let(:body)    { response_json }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that raises an error (with stubbed response)"
    end
  end

  # PATCH
  describe "#patch" do
    subject(:patch) { connection.patch(endpoint, body: body, context: context) }

    let(:method)  { :patch }
    let(:params)  { {} }
    let(:body)    { response_json }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that returns an error (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end
  end

  describe "#patch!" do
    subject(:patch!) { connection.patch!(endpoint, body: body, context: context) }

    let(:method)  { :patch }
    let(:params)  { {} }
    let(:body)    { response_json }
    let(:headers) { request_headers }

    context "success" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(typhoeus_response) }

      it_behaves_like "a Connection call that is successful (with stubbed response)"
      it_behaves_like "a Connection request with correct headers (with stubbed response)"
    end

    context "failure" do
      before { Typhoeus.stub("#{base_url}/#{endpoint}").and_return(failure_response) }

      it_behaves_like "a Connection call that raises an error (with stubbed response)"
    end
  end

  describe "url generation" do
    let(:expected_url) { "http://127.0.0.1:3000/v1/namespace/endpoint" }

    it { expect(connection.send(:url, "namespace/endpoint")).to eq(expected_url) }
    it { expect(connection.send(:url, "/namespace/endpoint")).to eq(expected_url) }
    it { expect(connection.send(:url, "namespace/endpoint/")).to eq(expected_url) }
    it { expect(connection.send(:url, "/namespace/endpoint/")).to eq(expected_url) }

    it { expect(connection.send(:url, %w(namespace endpoint))).to eq(expected_url) }
    it { expect(connection.send(:url, ["/namespace", "endpoint"])).to eq(expected_url) }
    it { expect(connection.send(:url, ["namespace", "endpoint/"])).to eq(expected_url) }
    it { expect(connection.send(:url, ["/namespace", "endpoint/"])).to eq(expected_url) }

    it { expect(connection.send(:url, ["namespace/", "/endpoint"])).to eq(expected_url) }
    it { expect(connection.send(:url, ["namespace/", "/endpoint/"])).to eq(expected_url) }
    it { expect(connection.send(:url, ["/namespace/", "/endpoint/"])).to eq(expected_url) }
    it { expect(connection.send(:url, ["/namespace/", "/endpoint"])).to eq(expected_url) }

    it { expect(connection.send(:url, ["/", :namespace, "/", "endpoint", "/"])).to eq(expected_url) }
    it { expect(connection.send(:url, :"namespace/endpoint")).to eq(expected_url) }
    it { expect(connection.send(:url, %i(namespace endpoint))).to eq(expected_url) }
  end
end
