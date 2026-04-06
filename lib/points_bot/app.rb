require "json"
require "rack/request"
require "rack/response"

require_relative "discord_interactions"

module PointsBot
  class App
    def call(env)
      request = Rack::Request.new(env)

      case [request.request_method, request.path_info]
      when ["GET", "/up"]
        text_response("OK\n")
      when ["POST", "/interactions"]
        DiscordInteractions.new(request).call
      else
        not_found
      end
    rescue StandardError => e
      warn("[points] #{e.class}: #{e.message}")
      json_response(500, { error: "internal_server_error" })
    end

    private

    def text_response(body, status: 200)
      [status, { "content-type" => "text/plain; charset=utf-8" }, [body]]
    end

    def json_response(status, payload)
      [status, { "content-type" => "application/json; charset=utf-8" }, [JSON.generate(payload)]]
    end

    def not_found
      text_response("Not found\n", status: 404)
    end
  end
end
