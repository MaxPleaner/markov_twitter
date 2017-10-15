
# ========================================================================
# Also see spec/node_spec.rb which covers manipulating the chain
# ========================================================================

using MarkovTwitter::TestHelperMethods

RSpec.describe "MarkovBuilder" do

  let(:phrase1) { get_sample_phrase_1 }
  let(:phrase2) { get_sample_phrase_2 }
  let(:sample_phrases) { [phrase1, phrase2] }
  let(:markov_builder) { MarkovTwitter::MarkovBuilder }

  describe "#initialize" do

    it "processes phrases and stores their values/linkages" do
      chain = markov_builder.new(phrases: sample_phrases)
      nodes = chain.nodes
      expect(nodes.keys.sort).to eq(%w{bat cat flat hat in the})
      %w{cat bat}.each do |word|
        validate_linkages(nodes[word],
          _next: {"in" => 1.0},
          prev: {"the" => 1.0},
          total_num_inputs: { next: 1, prev: 1 }
        )
      end
      %w{hat flat}.each do |word|
        validate_linkages(nodes[word],
          _next: {},
          prev: {"the" => 1.0},
          total_num_inputs: { next: 0, prev: 1 }
        )
      end
      validate_linkages(nodes["the"],
        _next: {"cat" => 0.25, "bat" => 0.25, "hat" => 0.25, "flat" => 0.25},
        prev: {"in" => 1.0},
        total_num_inputs: { next: 4, prev: 2}
      )
      validate_linkages(nodes["in"],
        _next: {"the" => 1},
        prev: {"cat" => 0.5, "bat" => 0.5},
        total_num_inputs: { next: 2, prev: 2}
      )
    end

  end

  describe "#evaluate" do

    around(:each) do |example|
      srand(0) # seeds the randomness 
      example.run
      srand() # unseeds the randomness
    end

    it "evaluates the chain into a random order" do
      chain = markov_builder.new(phrases: sample_phrases)
      results = 3.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
        "bat in the hat cat",
        "flat the bat in the",
        "the flat flat cat in"
      ]
    end

  end

end