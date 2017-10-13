TweetReader = MarkovTwitter::TweetReader

using MarkovTwitter::TestHelperMethods

RSpec.describe TweetReader do

  let(:invalid_authenticator) { build_invalid_authenticator }
  let(:valid_authenticator) { build_valid_authenticator }
  let(:sample_username) { get_sample_username }
  let(:sample_user_first_9_tweets) { get_sample_user_first_9_tweets }
  let(:sample_user_latest_tweet) { get_sample_user_latest_tweet }
  let(:invalid_username) { get_invalid_username }
  let(:many_tweets_username) { get_many_tweets_username } 
  let(:sample_username_tweets) do
    [
      get_sample_user_latest_tweet,
      *get_sample_user_first_9_tweets
    ].map { |tweet| { text: tweet, id: 0 } }
  end
  let(:many_tweets_username_tweets) do
    1.upto(20).map { |i| {text: "#{i}", id: 0 } }
  end

  context "#get_tweets" do

    it "raises an error if credentials are invalid" do  
      stub_twitter_token_request_with_invalid_credentials
      tweet_reader = TweetReader.new(client: invalid_authenticator.client)
      expect do
        tweet_reader.get_tweets(username: sample_username)
      end.to raise_error(Twitter::Error::Forbidden)
    end

    it "returns the correct latest tweets if passed a valid username" do
      stub_twitter_token_request_with_valid_credentials
      stub_twitter_user_lookup_request_with_valid_username(sample_username)
      stub_twitter_user_timeline_request(sample_username_tweets)
      tweet_reader = TweetReader.new(client: valid_authenticator.client)
      tweets = tweet_reader.get_tweets(username: sample_username)
      expect(tweets.first.text).to eq(sample_user_latest_tweet)
      expect(tweets.last(9).map(&:text)).to eq sample_user_first_9_tweets
    end

    it "returns only the latest 20 tweets" do
      stub_twitter_token_request_with_valid_credentials
      stub_twitter_user_lookup_request_with_valid_username(many_tweets_username)
      stub_twitter_user_timeline_request(many_tweets_username_tweets)
      tweet_reader = TweetReader.new(client: valid_authenticator.client)
      tweets = tweet_reader.get_tweets(username: many_tweets_username)
      expect(tweets.length).to eq(20)
    end

    it "raises an error if passed an invalid username" do
      stub_twitter_token_request_with_valid_credentials
      stub_twitter_user_lookup_request_with_invalid_username(invalid_username)      
      tweet_reader = TweetReader.new(client: valid_authenticator.client)
      expect do
        tweet_reader.get_tweets(username: invalid_username)
      end.to(
        raise_error(Twitter::Error::NotFound)
      )
    end

  end

end