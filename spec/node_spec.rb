using MarkovTwitter::TestHelperMethods

RSpec.describe "Node" do

  let(:phrase1) { get_sample_phrase_1 }
  let(:phrase2) { get_sample_phrase_2 }
  let(:sample_phrases) { [phrase1, phrase2] }
  let(:markov_builder_class) { MarkovTwitter::MarkovBuilder }
  let(:node_class) { markov_builder_class::Node }


  around(:each) do |example|
    srand(0) # seeds the randomness 
    example.run
    srand() # unseeds the randomness
  end

  describe "#initialize and attr_readers" do

    it "stores correct instance variables" do
      nodes = {}
      node = node_class.new(value: "foo", nodes: nodes)
      expect(node.value).to eq "foo"
      expect(node.linkages).to eq({ next: {}, prev: {} })
      expect(node.total_num_inputs).to eq({next: 0, prev: 0})
      expect(node.nodes).to eq nodes
    end

  end

  describe "#add_and_adjust_probabilities" do
    
    it "can add a :next option more probable by adding it multiple times" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the = chain.nodes["the"]
      cat = chain.nodes["cat"]
      bat = chain.nodes["bat"]
      # make the => bat => cat very probable
      20.times { the.add_and_adjust_probabilities :next, bat }
      20.times { bat.add_and_adjust_probabilities :next, cat }
      validate_linkages(the,
        _next: {
          "cat"=> 1/24.0, "hat"=> 1/24.0, "bat"=> 21/24.0, "flat"=> 1/24.0
        },
        prev: { "in" => 1 },
        total_num_inputs: { next: 24, prev: 2 }
      )
      validate_linkages(cat,
        _next: { "in" => 1 },
        prev: { "the" => 1/21.0, "bat" => 20/21.0},
        total_num_inputs: { next: 1, prev: 21 }
      )
      validate_linkages(bat,
        _next: { "in" => 1/21.0, "cat" => 20/21.0 },
        prev: { "the" => 1.0 },
        total_num_inputs: { next: 21, prev: 21 }
      )
      results = 5.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
        "bat cat in the bat",
        "hat in the bat cat",
        "the flat cat in the",
        "the bat cat in the",
        "cat in the bat cat"
      ]
    end

    it "can add a recursive :next option pointing to itself" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the = chain.nodes["the"]
      # make the => the very probable
      20.times { the.add_and_adjust_probabilities :next, the }
      validate_linkages(the,
        _next: {
          "cat"=> 1/24.0,
          "hat"=> 1/24.0,
          "bat"=> 1/24.0,
          "flat"=> 1/24.0,
          "the"=> 20/24.0
        },
        prev: {
          "the" => 20/22.0, "in" => 2/22.0
        },
        total_num_inputs: {next: 24, prev: 22}
      )
      results = 3.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
        "bat in the the the",
        "hat in the the the",
        "the bat in the the"
      ]
    end

    it "can add a node that wasn't already present in the chain" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the = chain.nodes["the"]
      rat = node_class.new(value: "rat", nodes: the.nodes)
      # make the => rat fairly likely
      10.times { the.add_and_adjust_probabilities :next, rat }
      validate_linkages(the,
        _next: {
          "bat" => 1/14.0,
          "cat" => 1/14.0,
          "hat" => 1/14.0,
          "flat" => 1/14.0,
          "rat" => 10/14.0
        },
        prev: { "in" => 1 },
        total_num_inputs: { next: 14, prev: 2 }
      )
      results = 3.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
        "bat in the rat cat",
        "flat rat the hat cat",
        "rat cat in the rat"
      ]     
    end

  end

  describe "#get_probability_unit" do

    it "determine a single input's weight using total_num_inputs" do
      chain = markov_builder_class.new phrases: ["foo bar foo car"]
      expect(chain.nodes["foo"].get_probability_unit(:next)).to eq(0.5)
    end

    it "raises an error if there were no inputs added" do
      chain = markov_builder_class.new phrases: ["foo"]
      expect {chain.nodes["foo"].get_probability_unit(:next) }.to(
        raise_error
      )
    end

  end 

  describe "#remove_and_adjust_probabilities" do

    it "can remove a certain word to make it less likely" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the, cat, bat, hat = chain.nodes.values_at *%w{the cat bat hat}
      # make the => cat/bat/hat impossible.
      %w{cat bat hat}.each do |word|
        # it's safe to run it excess times.
        5.times do
          the.remove_and_adjust_probabilities :next, chain.nodes[word]
        end
      end
      validate_linkages(the,
        _next: {
          "flat" => 1.0,
        },
        prev: {
          "in" => 1.0
        },
        total_num_inputs: { next: 1, prev: 2 }
      )
      results = 3.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
        "bat in the flat cat",
        "flat the flat in the",
        "the flat cat in the"
      ]
    end

  end

  describe "#update_opposite_direction" do

    it "calls the given method using the opposite direction" do
      chain = markov_builder_class.new phrases: ["foo bar"]
      foo,bar = chain.nodes.values_at *%w{foo bar}
      expect_fake_method_called_with_direction = -> (direction) {
        expect(bar).to receive(:send).with(
          :fake_method, direction, foo, :a, :b, false
        )
        expect(bar).not_to receive(:update_opposite_direction)
      }
      expect_fake_method_called_with_direction.call(:prev)
      foo.update_opposite_direction(:next, bar, :fake_method, :a, :b)
      expect_fake_method_called_with_direction.call(:next)
      foo.update_opposite_direction(:prev, bar, :fake_method, :a, :b)
    end

  end

  describe "#add_next_linkage" do

    it "calls add_and_adjust_probabilities with :next" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the, cat = chain.nodes.values_at *%w{the cat}
      expect(the).to receive(:add_and_adjust_probabilities).with(:next, cat)
      the.add_next_linkage cat
    end

  end

  describe "#add_prev_linkage" do

    it "calls add_and_adjust_probabilities with :prev" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the, cat = chain.nodes.values_at *%w{the cat}
      expect(the).to receive(:add_and_adjust_probabilities).with(:prev, cat)
      the.add_prev_linkage cat
    end

  end


  describe "#remove_next_linkage" do

    it "calls remove_and_adjust_probabilities with :next" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the, cat = chain.nodes.values_at *%w{the cat}
      expect(the).to receive(:remove_and_adjust_probabilities).with(:next, cat)
      the.remove_next_linkage cat      
    end

  end

  describe "#remove_prev_linkage" do

    it "calls remove_and_adjust_probabilities with :prev" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the, cat = chain.nodes.values_at *%w{the cat}
      expect(the).to receive(:remove_and_adjust_probabilities).with(:prev, cat)
      the.remove_prev_linkage cat      
    end

  end

  describe "#delete_linkage!" do

    it "can remove a node as an option entirely" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the, cat, bat, hat = chain.nodes.values_at *%w{the cat bat hat}
      # make the => cat/bat/hat impossible.
      # it's safe to run delete_linkage! excess times.
      %w{cat bat hat}.each do |word|
        5.times do
          the.delete_linkage! :next, chain.nodes[word]
        end
      end
      validate_linkages(the,
        _next: { "flat" => 1.0 },
        prev: { "in" => 1.0 },
        total_num_inputs: { next: 1, prev: 2 }
      )
      results = 3.times.map { chain.evaluate(length: 5) }
      # note this is the same result as the previous example.
      expect(results).to eq [
        "bat in the flat cat",
        "flat the flat in the",
        "the flat cat in the"
      ]
    end

  end

  describe "#add_linkage!" do

    it "can set an arbitrary probability at a node" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      the, flat = chain.nodes.values_at *%w{the flat}
      # set "flat" to 0.5, adjusting all the others
      the.add_linkage!(:next, flat, 0.5)
      validate_linkages(the,
        _next: {
          "flat" => 3/6.0,
          "cat" => 1/6.0,
          "bat" => 1/6.0,
          "hat" => 1/6.0
        },
        prev: { "in" => 1.0 },
        total_num_inputs: { next: 4, prev: 2}
      )
      # set "flat" to 1, removing all others
      the.add_linkage!(:next, flat, 1.0)
      validate_linkages(the,
        _next: { "flat" => 1.0 },
        prev: { "in" => 1.0 },
        total_num_inputs: { next: 1, prev: 2 }
      )
    end

  end
  
end