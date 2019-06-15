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

    get "/users" do
      content_type :json

      if params[:unauthorized]
        status 403
        { message: "Your favorite fake error message" }.to_json
      else
        offset, limit = *pagination

        {
          entries: RESPONSE_BODY[:entries].slice(offset...limit),
          total_entries: RESPONSE_BODY[:entries].count,
        }.to_json
      end
    end

    get "/users/:id" do
      content_type :json

      if params[:fake_error]
        status 422
        { message: "Your favorite fake error message" }.to_json
      else
        id = params["id"]
        user = RESPONSE_BODY[:entries].detect { |u| u[:id] == id }

        return user.to_json if user

        status 404
        return { message: "User with id = #{id} not found" }.to_json
      end
    end
  end

  RESPONSE_BODY ||=
    {
      entries: [
        {
          email: "no_one@example.com",
          id: "1",
          name: "Arya Stark",
        },
        {
          email: "jon_snow@example.com",
          id: "22",
          name: "Jon Snow",
        },
        {
          email: "sansa_stark@example.com",
          id: "333",
          name: "Sansa Stark",
        },
        {
          email: "melisandre@example.com",
          id: "4444",
          name: "The Red Woman",
        },
        {
          email: "sam@example.com",
          id: "55555",
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
