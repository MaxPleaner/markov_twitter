class MarkovTwitter::Authenticator

  attr_reader :client

  def initialize(api_key:, secret_key:)
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = api_key
      config.consumer_secret     = secret_key
    end
  end

end