RSpec.describe "test environment" do
  it "has environment variables set" do
    api_key, secret_key = ENV.values_at *%w{TWITTER_API_KEY TWITTER_SECRET_KEY}
    expect([api_key, secret_key].none? &:blank?).to be true
  end
end