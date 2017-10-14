
# Methods which are included into test case via refinement,
# so they don't interfere with application code
# and don't require a namespace.
module MarkovTwitter::TestHelperMethods
  
  # alias
  Authenticator = MarkovTwitter::Authenticator
  
  # Builds an authenticator instance with valid credentials.
  # Will raise an error unless the expected ENV vars are defined.
  # @return [Authenticator]
  def build_valid_authenticator
    Authenticator.new(
      api_key: ENV.fetch("TWITTER_API_KEY"),
      secret_key: ENV.fetch("TWITTER_SECRET_KEY")
    )
  end
  
  # Builds an authenticator instance with invalid credentials.
  # Should raise errors on subsequent operations.
  # @return [Authenticator]
  def build_invalid_authenticator
    Authenticator.new(api_key: "", secret_key: "")
  end

  # This is a twitter user I've created that has a fixed set of tweets.
  # It's there to make sure that fetching tweets works correctly.
  # @return [String]
  def get_sample_username
    "max_p_sample"
  end

  # The expected tweets of the user I manually posted to on Twitter.
  # @return [Array<String>]
  def get_sample_user_tweets
    [
      "don't ever change",
      "A long-term goal of mine is to create a water-based horror game. I've done some work on building this in Unity already.",
      "Many amazing looking animals can be kept in reasonably simple environments, but some require elaborate setups .",
      "I enjoy creating terrariums but it's a lot of work to keep everything balanced so that all the critters survive .",
      "Although I haven't had a cat myself, I have had aquariums, terrariums, and rodents at different points .",
      "i have personally never owned a pet cat, and I'm a bit allergic, but I still enjoy their company .",
      "carnivorous by nature, cats hunt many other wild animals such as gophers and mice. As a result, some people would prefer less outdoor cats .",
      "you have now unsubscribed to cat facts. respond with UNSUBSCRIBE to unsubscribe .",
      "egyption hairless cats are less allergenic than most other cats. they don't have hair and are probably less oily .",
      "the cat in the hat ate and sat. it got fat and couldn't catch a rat ."
    ]
  end

  # Converts strings into a specific structure that is used internally by
  # the twitter gem. Used for stubbing with Webmock.
  # @param strings [Array<String>]
  # @return [Array<Hash>] where each hash has :id and :text keys.
  def to_tweet_objects(strings)
    strings.map { |string| { id: 0, text: string } }
  end

  # Sample tweets for which the content does not matter - 
  # these are only used to test the pagination of Twitter results.
  # @return [Array<String>]
  def get_stubbed_many_tweets_user_tweets
    20.times.map &:to_s
  end

  # This user should raise an error when the twitter gem looks them up.
  # @return [String]
  def get_invalid_username
    "3u9r4j8fjniecn875jdpwqk32mdiy4584vuniwcoekpd932"
  end

  # A twitter user which has many tweets.
  # Used to test pagination of search results.
  # @return [String]
  def get_many_tweets_username
    "SFist"
  end

  # Makes twitter's oauth request succeed.
  # Returns without doing anything if DisableWebmock=true in ENV.
  # @return [void]
  def stub_twitter_token_request_with_valid_credentials
    return if ENV["DisableWebmock"] == "true"
    stub_request(
      :post, "https://api.twitter.com/oauth2/token"
    ).to_return(status: 200, body: "", headers: {})
  end

  # Makes twitter's oauth request fail
  # Returns without doing anything if DisableWebmock=true in ENV.
  # @return [void]
  def stub_twitter_token_request_with_invalid_credentials
    return if ENV["DisableWebmock"] == "true"
    stub_request(
      :post, "https://api.twitter.com/oauth2/token"
    ).to_return(status: 403, body: "", headers: {})
  end

  # Makes the twitter user lookup request succeed.
  # Returns without doing anything if DisableWebmock=true in ENV.
  # @return [void]
  def stub_twitter_user_lookup_request_with_valid_username(username)
    return if ENV["DisableWebmock"] == "true"
    stub_request( :get,
      "https://api.twitter.com/1.1/users/show.json?screen_name=#{username}"
    ).to_return(status: 200, body: {id: 0}.to_json, headers: {})
  end

  # Makes the twitter user lookup request fail.
  # Returns without doing anything if DisableWebmock=true in ENV.
  # @param username [String]
  # @return [void]
  def stub_twitter_user_lookup_request_with_invalid_username(username)
    return if ENV["DisableWebmock"] == "true"
    stub_request( :get,
      "https://api.twitter.com/1.1/users/show.json?screen_name=#{username}"
    ).to_return(status: 404, body: {id: 0}.to_json, headers: {})    
  end

  # Makes the twitter user timeline request succeed.
  # returns without doing anything if DisableWebmock=true in ENV
  # @param tweets_to_return [Array<Hash>]
  #   - the hashes have keys "id" and "text"
  # @return [void]
  def stub_twitter_user_timeline_request(tweets_to_return)
    return if ENV["DisableWebmock"] == "true"
    stub_request(
      :get,
      "https://api.twitter.com/1.1/statuses/user_timeline.json?user_id=0"
    ).to_return(status: 200, body: tweets_to_return.to_json, headers: {})
  end

  # This module can be added with `using MarkovTwitter::TestHelperMethods`.
  # It can also be added globally with `Object.include MarkovTwitter::TestHelperMethods`.
  refine Object do
    include MarkovTwitter::TestHelperMethods
  end

end