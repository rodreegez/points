#!/usr/bin/env ruby

require "bundler/setup"
require "dotenv/load"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "points_bot/db"
require "sequel/extensions/migration"

db = PointsBot::DB.connection
migrations_path = File.expand_path("../db/migrate", __dir__)

Sequel::Migrator.run(db, migrations_path)

puts "Migrations applied"
