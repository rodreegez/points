require "ed25519"
require "json"

require_relative "discord_request_verifier"

module PointsBot
  class DiscordInteractions
    DISCORD_PING = 1
    APPLICATION_COMMAND = 2
    CHANNEL_MESSAGE_WITH_SOURCE = 4
    PONG = 1

    def initialize(request, verifier: DiscordRequestVerifier.new(public_key: ENV.fetch("DISCORD_PUBLIC_KEY")))
      @request = request
      @verifier = verifier
    end

    def call
      body = request.body.read
      request.body.rewind

      return error_response(401, "invalid request signature") unless verifier.valid?(request, body)

      payload = JSON.parse(body)

      case payload.fetch("type")
      when DISCORD_PING
        ok(type: PONG)
      when APPLICATION_COMMAND
        handle_application_command(payload)
      else
        error_response(400, "unsupported interaction type")
      end
    rescue KeyError, JSON::ParserError
      error_response(400, "invalid request payload")
    end

    private

    attr_reader :request, :verifier

    def handle_application_command(payload)
      case payload.dig("data", "name")
      when "ping"
        ok(
          type: CHANNEL_MESSAGE_WITH_SOURCE,
          data: { content: "pong" }
        )
      else
        error_response(400, "unsupported command")
      end
    end

    def ok(payload)
      [
        200,
        { "content-type" => "application/json; charset=utf-8" },
        [JSON.generate(payload)]
      ]
    end

    def error_response(status, message)
      [
        status,
        { "content-type" => "application/json; charset=utf-8" },
        [JSON.generate(error: message)]
      ]
    end
  end
end
