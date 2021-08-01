require "graphql/client"
require "graphql/client/http"

module GitHubGraphQL
  HTTP = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
    def headers(context)
      {
        "User-Agent" => "My Client",
        "Authorization" => "bearer #{ENV['GITHUB_TOKEN']}"
      }
    end
  end  
  Schema = GraphQL::Client.load_schema(HTTP)
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end
