require "bundler/setup"
ENV["RACK_ENV"] = "test"
require "minitest/autorun"
require "sequel"

require_relative "../lib/points_bot/points_ledger"

class PointsLedgerTest < Minitest::Test
  def setup
    @db = Sequel.sqlite
    @db.create_table(:points_events) do
      primary_key :id
      String :guild_id, null: false
      String :user_id, null: false
      String :actor_user_id, null: false
      Integer :delta, null: false
      String :reason, text: true
      DateTime :created_at, null: false
    end
    @ledger = PointsBot::PointsLedger.new(db: @db)
  end

  def teardown
    @db.disconnect
  end

  def test_record_and_total_for_user
    @ledger.record!(guild_id: "guild-1", user_id: "user-1", actor_user_id: "admin", delta: 5)
    @ledger.record!(guild_id: "guild-1", user_id: "user-1", actor_user_id: "admin", delta: -2)

    assert_equal 3, @ledger.total_for(guild_id: "guild-1", user_id: "user-1")
  end

  def test_scoreboard_is_scoped_to_guild_and_sorted
    @ledger.record!(guild_id: "guild-1", user_id: "user-1", actor_user_id: "admin", delta: 5)
    @ledger.record!(guild_id: "guild-1", user_id: "user-2", actor_user_id: "admin", delta: 10)
    @ledger.record!(guild_id: "guild-2", user_id: "user-1", actor_user_id: "admin", delta: 50)

    assert_equal(
      [
        { user_id: "user-2", score: 10 },
        { user_id: "user-1", score: 5 }
      ],
      @ledger.scoreboard_for(guild_id: "guild-1")
    )
  end
end
