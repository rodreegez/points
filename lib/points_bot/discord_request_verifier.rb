require "ed25519"

module PointsBot
  class DiscordRequestVerifier
    TIMESTAMP_TOLERANCE_SECONDS = 300

    def initialize(public_key:)
      @verify_key = Ed25519::VerifyKey.new([public_key].pack("H*"))
    end

    def valid?(request, body)
      timestamp = request.get_header("HTTP_X_SIGNATURE_TIMESTAMP")
      signature = request.get_header("HTTP_X_SIGNATURE_ED25519")

      return false if timestamp.to_s.empty? || signature.to_s.empty?
      return false if stale_timestamp?(timestamp)

      verify_key.verify([signature].pack("H*"), "#{timestamp}#{body}")
      true
    rescue ArgumentError, Ed25519::VerifyError
      false
    end

    private

    attr_reader :verify_key

    def stale_timestamp?(timestamp)
      (Time.now.to_i - Integer(timestamp)).abs > TIMESTAMP_TOLERANCE_SECONDS
    rescue ArgumentError
      true
    end
  end
end
