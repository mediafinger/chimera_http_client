require "json"
require "sinatra/base"
require "sinatra/namespace"

class UsersServer < Sinatra::Base
  register Sinatra::Namespace

  class << self
    attr_accessor :endpoint_url
  end

  namespace "/api/v1" do
    before do
      content_type "application/json"
    end

    # timeout in the test is set to 0.2 seconds, so we don't have to wait 5s
    get "/errors/:code" do
      sleep 5 if params[:code] == "timeout"

      if params[:code].to_i == 0
        status 0
        return
      end

      status params[:code].to_i
      return { message: "error #{params[:code]}" }.to_json
    end

    post "/users" do
      if params[:unauthorized]
        status 403
        return { message: "No access rights" }.to_json
      else
        status 201
        return RESPONSE_BODY[:entries].last.to_json
      end
    end

    get "/users" do
      if params[:unauthorized]
        status 403
        return { message: "No access rights" }.to_json
      else
        offset, limit = *pagination

        {
          entries: RESPONSE_BODY[:entries].slice(offset...limit),
          total_entries: RESPONSE_BODY[:entries].count,
        }.to_json
      end
    end

    get "/users/:id" do
      if params[:fake_error]
        status 422
        return { message: "Your favorite fake error message" }.to_json
      else
        id = params["id"]
        user = RESPONSE_BODY[:entries].detect { |u| u[:id] == id }

        return user.to_json unless user.nil?

        status 404
        return { message: "User with id = #{id} not found" }.to_json
      end
    end

    patch "/users/:id" do
      id = params["id"]
      user = RESPONSE_BODY[:entries].detect { |u| u[:id] == id }

      return user.to_json unless user.nil?

      status 404
      return { message: "User with id = #{id} not found" }.to_json
    end

    put "/users/:id" do
      id = params["id"]
      user = RESPONSE_BODY[:entries].detect { |u| u[:id] == id }

      return user.to_json unless user.nil?

      status 404
      return { message: "User with id = #{id} not found" }.to_json
    end

    delete "/users/:id" do
      id = params["id"]
      user = RESPONSE_BODY[:entries].detect { |u| u[:id] == id }

      return user.to_json unless user.nil?

      status 404
      return { message: "User with id = #{id} not found" }.to_json
    end
  end

  RESPONSE_BODY ||=
    {
      entries: [
        {
          id: "1",
          email: "no_one@example.com",
          name: "Arya Stark",
        },
        {
          id: "22",
          email: "jon_snow@example.com",
          name: "Jon Snow",
        },
        {
          id: "333",
          email: "sansa_stark@example.com",
          name: "Sansa Stark",
        },
        {
          id: "4444",
          email: "melisandre@example.com",
          name: "The Red Woman",
        },
        {
          id: "55555",
          email: "sam@example.com",
          name: "Sam Tarwell",
        },
      ],
    }.freeze

  private

  def pagination
    page = (params[:page] || 1).to_i
    page_size = (params[:page_size] || 2).to_i
    limit = page * page_size
    offset = limit - page_size

    [offset, limit]
  end
end
