class MarkovTwitter::TweetReader

  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def get_tweets(username:)
    user = client.user(username)
    client.user_timeline(user)
  end

end