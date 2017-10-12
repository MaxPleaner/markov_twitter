using MarkovTwitter::TestHelperMethods
MarkovBuilder = MarkovTwitter::MarkovBuilder

RSpec.describe MarkovBuilder do

  let(:phrases) { get_sample_user_first_9_tweets }

  it "processes phrases and stores their values/linkages" do
    phrase1 = "the cat in the hat"
    phrase2 = "the bat in the flat"
    markov_builder = MarkovBuilder.new(phrases: [phrase1, phrase2])
    expect(markov_builder.nodes.keys.sort).to eq(%w{bat cat flat hat in the})
    y = 10.times.map { markov_builder.evaluate(length: 5) }
    binding.pry
  end

end