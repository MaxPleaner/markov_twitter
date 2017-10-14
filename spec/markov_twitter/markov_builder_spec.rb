using MarkovTwitter::TestHelperMethods

RSpec.describe "MarkovBuilder" do

  let(:phrase1) { "the cat in the hat" }
  let(:phrase2) { "the bat in the flat" }
  let(:sample_phrases) { [phrase1, phrase2] }
  let(:markov_builder) { MarkovTwitter::MarkovBuilder }

  describe "#initialize" do

    it "processes phrases and stores their values/linkages" do
      chain = markov_builder.new(phrases: sample_phrases)
      nodes = chain.nodes
      expect(nodes.keys.sort).to eq(%w{bat cat flat hat in the})
      %w{cat bat}.each do |word|
        expect(nodes[word].linkages[:next]).to eq({"in" => 1.0,})
        expect(nodes[word].linkages[:prev]).to eq({"the" => 1.0})
        expect(nodes[word].num_inputs_per_cell[:next]).to eq({"in" => 1})
        expect(nodes[word].num_inputs_per_cell[:prev]).to eq({"the" => 1})
        expect(nodes[word].total_num_inputs[:next]).to eq(1)
        expect(nodes[word].total_num_inputs[:prev]).to eq(1)
      end
      %w{hat flat}.each do |word|
        expect(nodes[word].linkages[:next]).to eq({})
        expect(nodes[word].linkages[:prev]).to eq({"the" => 1.0})
        expect(nodes[word].num_inputs_per_cell[:next]).to eq({})
        expect(nodes[word].num_inputs_per_cell[:prev]).to eq({"the" => 1})
        expect(nodes[word].total_num_inputs[:next]).to eq(0)
        expect(nodes[word].total_num_inputs[:prev]).to eq(1)

      end
      expect(nodes["the"].linkages[:next]).to eq({
        "cat" => 0.25, "bat" => 0.25, "hat" => 0.25, "flat" => 0.25
      })
      expect(nodes["the"].linkages[:prev]).to eq({"in" => 1.0})
      expect(nodes["the"].num_inputs_per_cell[:next]).to eq({
        "cat" => 1, "bat" => 1, "hat" => 1, "flat" => 1
      })
      expect(nodes["the"].num_inputs_per_cell[:prev]).to eq({"in" => 2})
      expect(nodes["the"].total_num_inputs[:next]).to eq(4)
      expect(nodes["the"].total_num_inputs[:prev]).to eq(2)
      expect(nodes["in"].linkages[:next]).to eq({
        "the" => 1
      })
      expect(nodes["in"].linkages[:prev]).to eq({"cat" => 0.5, "bat" => 0.5})
      expect(nodes["in"].num_inputs_per_cell[:next]).to eq({
        "the" => 2
      })
      expect(nodes["in"].num_inputs_per_cell[:prev]).to eq({
        "cat" => 1, "bat" => 1
      })
      expect(nodes["in"].total_num_inputs[:next]).to eq(2)
      expect(nodes["in"].total_num_inputs[:prev]).to eq(2)
    end

  end

  describe "#evaluate" do

    it "evaluates the chain into a random order" do
      srand(0) # seeds the randomness 
      chain = markov_builder.new(phrases: sample_phrases)
      results = 3.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
        "bat in the hat cat",
        "flat the bat in the",
        "the flat flat cat in"
      ]
      srand() # unseeds the randomness
    end
    
  end

end