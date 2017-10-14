# Wrapper for the twitter gem's client.
class MarkovTwitter::Authenticator

  attr_reader :client

  # @param api_key [String] should be stored in ENV var
  # @param secret_key [String] should be stored in ENV var
  def initialize(api_key:, secret_key:)
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = api_key
      config.consumer_secret     = secret_key
    end
  end

end