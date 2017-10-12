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
  def get_sample_user_first_10_tweets
    9.downto(0).to_a.map &:to_s
  end

  refine Object do
    include MarkovTwitter::TestHelperMethods
  end

end