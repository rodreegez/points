require_relative "db"

module PointsBot
  class PointsLedger
    def initialize(db: DB.connection)
      @db = db
    end

    def record!(guild_id:, user_id:, actor_user_id:, delta:, reason: nil, created_at: Time.now.utc)
      events.insert(
        guild_id: guild_id,
        user_id: user_id,
        actor_user_id: actor_user_id,
        delta: delta,
        reason: reason,
        created_at: created_at
      )
    end

    def total_for(guild_id:, user_id:)
      events
        .where(guild_id: guild_id, user_id: user_id)
        .sum(:delta)
        .to_i
    end

    def scoreboard_for(guild_id:, limit: 10)
      events
        .where(guild_id: guild_id)
        .group(:user_id)
        .select(:user_id) { sum(delta).as(score) }
        .order(Sequel.desc(:score), :user_id)
        .limit(limit)
        .map { |row| { user_id: row[:user_id], score: row[:score].to_i } }
    end

    private

    attr_reader :db

    def events
      db[:points_events]
    end
  end
end
