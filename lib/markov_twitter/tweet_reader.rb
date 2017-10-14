# Fetches the latest tweets.
class MarkovTwitter::TweetReader

  # @!attribute [r] client
  #   @return [Object], an instance of Twitter::REST::Client
  attr_reader :client

  # @param client [Twitter::REST::Client]
  def initialize(client:)
    @client = client
  end

  # @param username [String] must exist or this will raise an error
  # @return [Array<Hash>]
  #   - the hashes will have :text and :id keys
  def get_tweets(username:)
    user = client.user(username)
    client.user_timeline(user)
  end

end