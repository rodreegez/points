Sequel.migration do
  change do
    create_table?(:points_events) do
      primary_key :id
      String :guild_id, null: false
      String :user_id, null: false
      String :actor_user_id, null: false
      Integer :delta, null: false
      String :reason, text: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index [:guild_id, :user_id]
      index [:guild_id, :created_at]
    end
  end
end
