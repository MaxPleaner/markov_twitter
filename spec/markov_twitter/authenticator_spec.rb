Authenticator = MarkovTwitter::Authenticator

using MarkovTwitter::TestHelperMethods

RSpec.describe Authenticator do

  let(:authenticator) { build_valid_authenticator }

  it "initializes a new twitter client when given credentials" do 
    expect(authenticator.client).to be_a Twitter::REST::Client
  end

end