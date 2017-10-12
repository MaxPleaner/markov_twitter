# methods which are included into test case via refinement,
# so they don't interfere with application code.
module MarkovTwitter::TestHelperMethods
  
  def build_valid_authenticator
    Authenticator.new(
      api_key: ENV["TWITTER_API_KEY"],
      secret_key: ENV["TWITTER_SECRET_KEY"]
    )
  end
  
  def build_invalid_authenticator
    Authenticator.new(api_key: "", secret_key: "")
  end

  # This is a twitter user I've created that has a fixed set of tweets.
  # It's there to make sure that fetching tweets works correctly.
  def get_sample_username
    "max_p_sample"
  end

  # This is the latest tweet of the sample user
  def get_sample_user_latest_tweet
    "don't ever change"
  end

  def get_invalid_username
    SecureRandom.urlsafe_base64
  end

  # ordered from newest to oldest
  def get_sample_user_first_9_tweets
  [
    "A long-term goal of mine is to create a water-based horror game. I've done some work on building this in Unity already.",
   "Many amazing looking animals can be kept in reasonably simple environments, but some require elaborate setups.",
   "I enjoy creating terrariums but it's a lot of work to keep everything balanced so that all the critters survive.",
   "Although I haven't had a cat myself, I have had aquariums, terrariums, and rodents at different points.",
   "i have personally never owned a pet cat, and I'm a bit allergic, but I still enjoy their company.",
   "carnivorous by nature, cats hunt many other wild animals such as gophers and mice. As a result, some people would prefer less outdoor cats.",
   "you have now unsubscribed to cat facts. respond with UNSUBSCRIBE to unsubscribe.",
   "egyption hairless cats are less allergenic than most other cats. they don't have hair and are probably less oily.",
   "the cat in the hat ate and sat. it got fat and couldn't catch a rat."
 ]
  end

  def get_many_tweets_username
    "SFist"
  end

  refine Object do
    include MarkovTwitter::TestHelperMethods
  end

end