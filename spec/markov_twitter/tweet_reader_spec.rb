Authenticator = MarkovTwitter::Authenticator
TweetReader = MarkovTwitter::TweetReader

using MarkovTwitter::TestHelperMethods

RSpec.describe TweetReader do

  let(:invalid_authenticator) { build_invalid_authenticator }
  let(:valid_authenticator) { build_valid_authenticator }
  let(:sample_username) { get_sample_username }
  let(:sample_user_first_10_tweets) { get_sample_user_first_10_tweets }
  let(:sample_user_latest_tweet) { get_sample_user_latest_tweet }
  let(:invalid_username) { get_invalid_username }

  context "#get_tweets" do

    it "raises an error if credentials are invalid" do
      tweet_reader = TweetReader.new(client: invalid_authenticator.client)
      expect do
        tweet_reader.get_tweets(username: sample_username)
      end.to raise_error(Twitter::Error::Forbidden)
    end

    it "returns the latest tweets if passed a valid username" do
      tweet_reader = TweetReader.new(client: valid_authenticator.client)
      tweets = tweet_reader.get_tweets(username: sample_username)
      expect(tweets.first.text).to eq(sample_user_latest_tweet)
      expect(tweets.last(9).map(&:text)).to match_array(
        sample_user_first_10_tweets.last(9)
      )
    end

    it "raises an error if passed an invalid username" do
      tweet_reader = TweetReader.new(client: valid_authenticator.client)
      expect do
        tweet_reader.get_tweets(username: invalid_username)
      end.to raise_error(Twitter::Error::NotFound)
    end

  end

end