using MarkovTwitter::TestHelperMethods
MarkovBuilder = MarkovTwitter::MarkovBuilder

RSpec.describe MarkovBuilder do

  it "processes phrases and stores their values/linkages" do
    srand(0) # seeds the randomness
    phrase1 = "the cat in the hat"
    phrase2 = "the bat in the flat"
    markov_builder = MarkovBuilder.new(phrases: [phrase1, phrase2])
    expect(markov_builder.nodes.keys.sort).to eq(%w{bat cat flat hat in the})
    results = 3.times.map { markov_builder.evaluate(length: 5) }
    expect(results).to eq [
      "bat in the hat the",
      "hat hat cat in the",
      "in the flat the cat"
    ]
    srand() # unseeds the randomness
  end

end