require "logger"
require "sequel"

module PointsBot
  module DB
    module_function

    def connection(url: ENV["DATABASE_URL"], logger: default_logger)
      raise KeyError, "DATABASE_URL is not set" if url.to_s.empty?

      @connections ||= {}
      @connections[url] ||= Sequel.connect(url, logger: logger, max_connections: 5)
    end

    def disconnect!
      return unless defined?(@connections) && @connections

      @connections.each_value(&:disconnect)
      @connections.clear
    end

    def default_logger
      return unless ENV["RACK_ENV"] == "development"

      Logger.new($stdout)
    end
  end
end
