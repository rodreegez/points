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

  def test_points_interaction_records_points_and_returns_total
    verifier = verifier_mock(valid: true)
    ledger = ledger_stub(total: 7)
    payload = {
      type: 2,
      guild_id: "guild-1",
      member: { user: { id: "admin-1" } },
      data: {
        name: "points",
        options: [
          { name: "user", value: "user-1" },
          { name: "delta", value: 7 },
          { name: "reason", value: "helpful answer" }
        ]
      }
    }

    handler = PointsBot::DiscordInteractions.new(mock_request(payload), verifier: verifier, ledger: ledger)
    status, _headers, body = handler.call

    assert_equal 200, status
    assert_equal(
      {
        "type" => 4,
        "data" => { "content" => "<@user-1> now has 7 points. Reason: helpful answer" }
      },
      JSON.parse(body.join)
    )
  end

  def test_scoreboard_interaction_returns_ranked_scores
    verifier = verifier_mock(valid: true)
    ledger = Struct.new(:scores) do
      def scoreboard_for(guild_id:)
        raise "wrong guild" unless guild_id == "guild-1"

        scores
      end
    end.new(
      [
        { user_id: "user-2", score: 10 },
        { user_id: "user-1", score: 5 }
      ]
    )
    payload = {
      type: 2,
      guild_id: "guild-1",
      data: { name: "scoreboard" }
    }

    handler = PointsBot::DiscordInteractions.new(mock_request(payload), verifier: verifier, ledger: ledger)
    status, _headers, body = handler.call

    assert_equal 200, status
    assert_equal(
      {
        "type" => 4,
        "data" => { "content" => "Scoreboard\n1. <@user-2>: 10\n2. <@user-1>: 5" }
      },
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

  def ledger_stub(total:)
    Struct.new(:inserted, :total) do
      def record!(**attrs)
        self.inserted = attrs
      end

      def total_for(guild_id:, user_id:)
        raise "wrong guild" unless guild_id == inserted[:guild_id]
        raise "wrong user" unless user_id == inserted[:user_id]

        total
      end
    end.new(nil, total)
  end
end
