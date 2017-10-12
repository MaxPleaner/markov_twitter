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

  context "#get_tweets" do

    it "raises an error if credentials are invalid" do  
      tweet_reader = TweetReader.new(client: invalid_authenticator.client)
      expect do
        tweet_reader.get_tweets(username: sample_username)
      end.to raise_error(Twitter::Error::Forbidden)
    end

    it "returns the correct latest tweets if passed a valid username" do
      tweet_reader = TweetReader.new(client: valid_authenticator.client)
      tweets = tweet_reader.get_tweets(username: sample_username)
      expect(tweets.first.text).to eq(sample_user_latest_tweet)
      expect(tweets.last(9).map(&:text)).to eq sample_user_first_9_tweets
    end

    it "returns only the latest 20 tweets" do
      tweet_reader = TweetReader.new(client: valid_authenticator.client)
      tweets = tweet_reader.get_tweets(username: many_tweets_username)
      expect(tweets.length).to eq(20)
    end

    it "raises an error if passed an invalid username" do
      tweet_reader = TweetReader.new(client: valid_authenticator.client)
      expect { tweet_reader.get_tweets(username: invalid_username) }.to(
        raise_error(Twitter::Error::NotFound)
      )
    end

  end

end