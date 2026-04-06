require "ed25519"
require "json"

require_relative "discord_request_verifier"
require_relative "points_ledger"

module PointsBot
  class DiscordInteractions
    DISCORD_PING = 1
    APPLICATION_COMMAND = 2
    CHANNEL_MESSAGE_WITH_SOURCE = 4
    PONG = 1

    def initialize(request, verifier: DiscordRequestVerifier.new(public_key: ENV.fetch("DISCORD_PUBLIC_KEY")), ledger: nil)
      @request = request
      @verifier = verifier
      @ledger = ledger
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
      when "points"
        handle_points_command(payload)
      when "scoreboard"
        handle_scoreboard_command(payload)
      else
        error_response(400, "unsupported command")
      end
    end

    def handle_points_command(payload)
      guild_id = payload["guild_id"]
      return command_message("`/points` can only be used in a server.") unless guild_id

      target_user_id = option_value(payload, "user")
      delta = option_value(payload, "delta")
      reason = option_value(payload, "reason")
      actor_user_id = payload.dig("member", "user", "id") || payload.dig("user", "id")

      return error_response(400, "missing command options") unless target_user_id && delta && actor_user_id

      ledger.record!(
        guild_id: guild_id,
        user_id: target_user_id,
        actor_user_id: actor_user_id,
        delta: Integer(delta),
        reason: reason
      )

      total = ledger.total_for(guild_id: guild_id, user_id: target_user_id)
      summary = "<@#{target_user_id}> now has #{total} point#{pluralize(total)}."
      summary = "#{summary} Reason: #{reason}" if reason && !reason.empty?

      command_message(summary)
    rescue ArgumentError
      error_response(400, "invalid points value")
    end

    def handle_scoreboard_command(payload)
      guild_id = payload["guild_id"]
      return command_message("`/scoreboard` can only be used in a server.") unless guild_id

      scores = ledger.scoreboard_for(guild_id: guild_id)

      if scores.empty?
        command_message("No points have been recorded yet.")
      else
        lines = scores.each_with_index.map do |entry, index|
          "#{index + 1}. <@#{entry[:user_id]}>: #{entry[:score]}"
        end

        command_message("Scoreboard\n#{lines.join("\n")}")
      end
    end

    def option_value(payload, name)
      options = payload.dig("data", "options") || []
      option = options.find { |entry| entry["name"] == name }
      option && option["value"]
    end

    def command_message(content)
      ok(
        type: CHANNEL_MESSAGE_WITH_SOURCE,
        data: { content: content }
      )
    end

    def pluralize(count)
      count == 1 ? "" : "s"
    end

    def ledger
      @ledger ||= PointsLedger.new
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
