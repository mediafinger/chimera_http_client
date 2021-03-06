require "server_spec_helper"

RSpec.shared_examples "a Connection call that is successful" do
  it { expect(subject).to be_kind_of(ChimeraHttpClient::Response) }

  it { expect(subject.code).to eq(response_code) }
  it { expect(subject.body).to eq(response_body.to_json) }
  it { expect(subject.time).to be_truthy }
  it { expect(subject.response).to be_a(Typhoeus::Response) }

  it { expect(subject.parsed_body).to eq(response_body) }
  it { expect(subject.error?).to be false }

  it { expect { subject }.not_to raise_error }
end

RSpec.shared_examples "a Connection call that returns an error" do
  it { expect(subject).to be_kind_of(ChimeraHttpClient::Error) }

  it { expect(subject.error?).to be true }
  it { expect(subject.code).to eq(failure_code) }
  it { expect(subject.body).to eq(failure_body.to_json) }
  it { expect(subject.message).to eq(failure_body.to_json) }
  it { expect(subject.time).to be_truthy }
end

RSpec.shared_examples "a Connection call that raises an error" do
  it "raises an error" do
    expect { subject }.to raise_error(ChimeraHttpClient::Error)
  end
end

RSpec.shared_examples "a Connection request with correct headers" do
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
      }
    )
  end
end

describe ChimeraHttpClient::Connection do
  let(:connection) { described_class.new(base_url: base_url) }
  let(:base_url) { "#{UsersServer.endpoint_url}/api/v1" }

  let(:endpoint)      { "users/22" }
  let(:response_code) { 200 }
  let(:response_body) { { "id" => "22", "email" => "jon_snow@example.com", "name" => "Jon Snow" } }

  let(:failure_code) { 404 }
  let(:failure_body) { { message: "User with id = #{failure_code} not found" } }

  let(:request_headers) { { "Content-Type" => "application/json" } }

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

  # GET
  describe "#get" do
    subject(:get) { connection.get(endpoint) }

    let(:method)  { :get }
    let(:params)  { {} }
    let(:body)    { nil }
    let(:headers) { request_headers }

    context "success" do
      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"
    end

    context "failure" do
      let(:endpoint) { "users/404" }

      it_behaves_like "a Connection call that returns an error"
      it_behaves_like "a Connection request with correct headers"
    end
  end

  describe "#get!" do
    subject(:get!) { connection.get!(endpoint) }

    let(:method)  { :get }
    let(:params)  { {} }
    let(:body)    { nil }
    let(:headers) { request_headers }

    context "success" do
      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"
    end

    context "failure" do
      let(:endpoint) { "users/404" }

      it_behaves_like "a Connection call that raises an error"
    end
  end

  # POST
  describe "#post" do
    subject(:post) { connection.post(endpoint, body: body) }

    let(:method)  { :post }
    let(:body)    { response_body.to_json }
    let(:params)  { {} }
    let(:headers) { request_headers }
    let(:response_code) { 201 }

    context "success" do
      let(:endpoint) { "users" }
      let(:response_body) { { "id" => "55555", "email" => "sam@example.com", "name" => "Sam Tarwell" } }

      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"
    end

    context "failure" do
      let(:endpoint) { "users?unauthorized=true" }
      let(:failure_code) { 403 }
      let(:failure_body) { { message: "No access rights" } }

      it_behaves_like "a Connection call that returns an error"
      it_behaves_like "a Connection request with correct headers"
    end

    context "missing body" do
      let(:endpoint) { "users" }
      let(:body) { nil }

      it "raises an error" do
        expect { post }.to raise_error(ChimeraHttpClient::ParameterMissingError)
      end
    end
  end

  describe "#post!" do
    subject(:post!) { connection.post!(endpoint, body: body) }

    let(:method)  { :post }
    let(:params)  { {} }
    let(:body)    { response_body.to_json }
    let(:headers) { request_headers }
    let(:response_code) { 201 }

    context "success" do
      let(:endpoint) { "users" }
      let(:response_body) { { "id" => "55555", "email" => "sam@example.com", "name" => "Sam Tarwell" } }

      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"
    end

    context "failure" do
      let(:endpoint) { "users?unauthorized=true" }
      let(:failure_code) { 403 }
      let(:failure_body) { { message: "No access rights" } }

      it_behaves_like "a Connection call that raises an error"
    end

    context "missing body" do
      let(:endpoint) { "users" }
      let(:body) { nil }

      it "raises an error" do
        expect { post! }.to raise_error(ChimeraHttpClient::ParameterMissingError)
      end
    end
  end

  # delete
  describe "#delete" do
    subject(:delete) { connection.delete(endpoint, body: body) }

    let(:method)  { :delete }
    let(:params)  { {} }
    let(:body)    { nil }
    let(:headers) { request_headers }

    context "success" do
      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"

      context "with body" do
        let(:body) { { number: "+493012345678" }.to_json }

        it_behaves_like "a Connection call that is successful"
        it_behaves_like "a Connection request with correct headers"
      end
    end

    context "failure" do
      let(:endpoint) { "users/404" }

      it_behaves_like "a Connection call that returns an error"
      it_behaves_like "a Connection request with correct headers"
    end
  end

  describe "#delete!" do
    subject(:delete!) { connection.delete!(endpoint, body: body) }

    let(:method)  { :delete }
    let(:params)  { {} }
    let(:body)    { nil }
    let(:headers) { request_headers }

    context "success" do
      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"

      context "with body" do
        let(:body) { { number: "+493012345678" }.to_json }

        it_behaves_like "a Connection call that is successful"
        it_behaves_like "a Connection request with correct headers"
      end
    end

    context "failure" do
      let(:endpoint) { "users/404" }

      it_behaves_like "a Connection call that raises an error"
    end
  end

  # PUT
  describe "#put" do
    subject(:put) { connection.put(endpoint, body: body) }

    let(:method)  { :put }
    let(:params)  { {} }
    let(:body)    { response_body.to_json }
    let(:headers) { request_headers }

    context "success" do
      let(:endpoint) { "users/22" }

      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"
    end

    context "failure" do
      let(:endpoint) { "users/404" }

      it_behaves_like "a Connection call that returns an error"
      it_behaves_like "a Connection request with correct headers"
    end
  end

  describe "#put!" do
    subject(:put!) { connection.put!(endpoint, body: body) }

    let(:method)  { :put }
    let(:params)  { {} }
    let(:body)    { response_body.to_json }
    let(:headers) { request_headers }

    context "success" do
      let(:endpoint) { "users/22" }

      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"
    end

    context "failure" do
      let(:endpoint) { "users/404" }

      it_behaves_like "a Connection call that raises an error"
    end
  end

  # PATCH
  describe "#patch" do
    subject(:patch) { connection.patch(endpoint, body: body) }

    let(:method)  { :patch }
    let(:params)  { {} }
    let(:body)    { response_body.to_json }
    let(:headers) { request_headers }

    context "success" do
      let(:endpoint) { "users/22" }

      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"
    end

    context "failure" do
      let(:endpoint) { "users/404" }

      it_behaves_like "a Connection call that returns an error"
      it_behaves_like "a Connection request with correct headers"
    end
  end

  describe "#patch!" do
    subject(:patch!) { connection.patch!(endpoint, body: body) }

    let(:method)  { :patch }
    let(:params)  { {} }
    let(:body)    { response_body.to_json }
    let(:headers) { request_headers }

    context "success" do
      let(:endpoint) { "users/22" }

      it_behaves_like "a Connection call that is successful"
      it_behaves_like "a Connection request with correct headers"
    end

    context "failure" do
      let(:endpoint) { "users/404" }

      it_behaves_like "a Connection call that raises an error"
    end
  end

  describe "url generation" do
    let(:expected_url) { "#{base_url}/namespace/endpoint" }

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
