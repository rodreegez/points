require "bundler/setup"
ENV["RACK_ENV"] = "test"
require "dotenv/load"
require "json"
require "minitest/autorun"
require "rack/test"

require_relative "../lib/points_bot/app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  TEST_PUBLIC_KEY = "1" * 64

  def app
    ENV["DISCORD_PUBLIC_KEY"] = TEST_PUBLIC_KEY
    PointsBot::App.new
  end

  def test_healthcheck
    get "/up"

    assert_equal 200, last_response.status
    assert_equal "OK\n", last_response.body
  end

  def test_ping_interaction_returns_pong
    verifier = verifier_mock(valid: true)
    payload = {
      type: 2,
      data: { name: "ping" }
    }

    handler = PointsBot::DiscordInteractions.new(mock_request(payload), verifier: verifier)
    status, headers, body = handler.call

    assert_equal 200, status
    assert_equal "application/json; charset=utf-8", headers["content-type"]
    assert_equal(
      { "type" => 4, "data" => { "content" => "pong" } },
      JSON.parse(body.join)
    )
  end

  def test_invalid_signature_is_rejected
    verifier = verifier_mock(valid: false)
    payload = { type: 1 }

    handler = PointsBot::DiscordInteractions.new(mock_request(payload), verifier: verifier)
    status, = handler.call

    assert_equal 401, status
  end

  private

  def mock_request(payload)
    body = StringIO.new(JSON.generate(payload))
    Struct.new(:body) do
      def get_header(_name)
        nil
      end
    end.new(body)
  end

  def verifier_mock(valid:)
    Struct.new(:result) do
      def valid?(_request, _body)
        result
      end
    end.new(valid)
  end
end
