using MarkovTwitter::TestHelperMethods
MarkovBuilder = MarkovTwitter::MarkovBuilder

RSpec.describe MarkovBuilder do

  let(:phrase1) { "the cat in the hat" }
  let(:phrase2) { "the bat in the flat" }
  let(:sample_phrases) { [phrase1, phrase2] }

  context "naive interpretation" do

    it "processes phrases and stores their values/linkages" do
      markov_builder = MarkovBuilder.new(phrases: sample_phrases)
      nodes = markov_builder.nodes
      expect(nodes.keys.sort).to eq(%w{bat cat flat hat in the})
      %w{cat bat}.each do |word|
        expect(nodes[word].linkages[:next].map(&:value)).to eq(%w{in})
        expect(nodes[word].linkages[:prev].map(&:value)).to eq(%w{the})
      end
      %w{hat flat}.each do |word|
        expect(nodes[word].linkages[:next].map(&:value)).to eq(%w{})
        expect(nodes[word].linkages[:prev].map(&:value)).to eq(%w{the})
      end
      expect(nodes["the"].linkages[:next].map(&:value)).to eq(%w{cat hat bat flat})
      expect(nodes["the"].linkages[:prev].map(&:value)).to eq(%w{in in})
      expect(nodes["in"].linkages[:next].map(&:value)).to eq(%w{the the})
      expect(nodes["in"].linkages[:prev].map(&:value)).to eq(%w{cat bat})
    end

    it "evaluates the chain into a random order" do
      srand(0) # seeds the randomness 
      markov_builder = MarkovBuilder.new(phrases: sample_phrases)
      results = 3.times.map { markov_builder.evaluate(length: 5) }
      expect(results).to eq [
        "bat in the hat the",
        "hat hat cat in the",
        "in the flat the cat"
      ]
      srand() # unseeds the randomness
    end

  end

end