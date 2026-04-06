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
    },
    {
      name: "points",
      type: 1,
      description: "Award or deduct points for a server member",
      options: [
        {
          type: 6,
          name: "user",
          description: "Member to update",
          required: true
        },
        {
          type: 4,
          name: "delta",
          description: "Positive or negative points change",
          required: true,
          min_value: -1000,
          max_value: 1000
        },
        {
          type: 3,
          name: "reason",
          description: "Optional note for the change",
          required: false,
          max_length: 200
        }
      ]
    },
    {
      name: "scoreboard",
      type: 1,
      description: "Show the current server leaderboard"
    }
  ]
)

response = http.request(request)

abort("Discord API error: #{response.code} #{response.body}") unless response.is_a?(Net::HTTPSuccess)

puts response.body
