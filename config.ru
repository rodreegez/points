require "bundler/setup"
require "dotenv/load"

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "points_bot/app"

run PointsBot::App.new
