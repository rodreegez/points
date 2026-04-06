#!/usr/bin/env ruby

require "bundler/setup"
require "dotenv/load"
require "json"
require "net/http"
require "uri"

app_id = ENV.fetch("DISCORD_APP_ID")
bot_token = ENV.fetch("DISCORD_BOT_TOKEN")

uri = URI("https://discord.com/api/v10/applications/#{app_id}/commands")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Put.new(uri)
request["Authorization"] = "Bot #{bot_token}"
request["Content-Type"] = "application/json"
request.body = JSON.generate(
  [
    {
      name: "ping",
      type: 1,
      description: "Check whether the bot is alive"
    }
  ]
)

response = http.request(request)

abort("Discord API error: #{response.code} #{response.body}") unless response.is_a?(Net::HTTPSuccess)

puts response.body
