RSpec.describe "the test environment itself" do
  it "has environment variables set" do
    api_key, secret_key = %w{
      TWITTER_API_KEY TWITTER_SECRET_KEY
    }.map &ENV.method(:fetch)
    expect([api_key, secret_key].none? &:blank?).to be true
  end
end