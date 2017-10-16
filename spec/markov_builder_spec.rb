
# ========================================================================
# Also see spec/node_spec.rb which covers manipulating the chain
# ========================================================================

using MarkovTwitter::TestHelperMethods

RSpec.describe "MarkovBuilder" do

  let(:phrase1) { get_sample_phrase_1 }
  let(:phrase2) { get_sample_phrase_2 }
  let(:sample_phrases) { [phrase1, phrase2] }
  let(:markov_builder_class) { MarkovTwitter::MarkovBuilder }
  let(:node_class) { markov_builder_class::Node }

  describe "#initialize" do

    it "processes phrases and stores their values/linkages" do
      chain = markov_builder_class.new(phrases: sample_phrases)
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

  describe ".split_phrase" do

    it "splits on consecutive whitespace" do
      phrase = "hello .. world   ...   "
      expect(
        markov_builder_class.split_phrase(phrase)
      ).to eq %w{hello .. world ...} 
    end

  end

  describe "#process_phrase" do

    it "splits the phrase and adds each pair of nodes" do
      chain = markov_builder_class.new
      phrase = "hello .. world ...   "
      split_phrase = markov_builder_class.split_phrase phrase
      expect(markov_builder_class).to(
        receive(:split_phrase).with(phrase).and_call_original
      )
      nodes = split_phrase.map &chain.method(:construct_node)
      nodes.each_index do |idx|
        expect(chain).to(
          receive(:construct_node).with(nodes[idx].value).and_return(
            nodes[idx]
          )
        )
        if nodes[idx + 1]
          expect(chain).to(
            receive(:construct_node).with(nodes[idx + 1]&.value).and_return(
              nodes[idx + 1]
            )
          )
        end
        expect(chain).to(
          receive(:add_nodes).with(*[nodes[idx], nodes[idx + 1]].compact)
        )
      end
      chain.process_phrase phrase
    end

  end

  describe "#add_nodes" do

    context "falsy node_val1 and falsy node_val2" do

      it "raises an error" do
        chain = markov_builder_class.new
        expect { chain.add_nodes nil }.to raise_error ArgumentError
      end

    end

    context "truthy node_val1 and falsy node_val2" do
      
      it "adds node_val1 to the dict and doesn't call add_linkages" do
        chain = markov_builder_class.new
        node1 = node_class.new(value: "foo", nodes: chain.nodes)
        expect(chain).not_to receive(:add_linkages)
        chain.add_nodes node1, false
        expect(chain.nodes[node1.value]).to eq(node1)
        expect(chain.nodes).not_to have_key false
      end

    end

    context "truthy node_val1 and truthy node_val2" do

      it "adds both vals to the dict and adds linkages" do
        chain = markov_builder_class.new
        node1 = node_class.new(value: "foo", nodes: chain.nodes)
        node2 = node_class.new(value: "bar", nodes: chain.nodes)
        expect(chain).to receive(:add_linkages).with(node1, node2)
        chain.add_nodes node1, node2
        expect(chain.nodes[node1.value]).to eq(node1)
        expect(chain.nodes[node2.value]).to eq(node2)
      end

    end

  end

  describe "#construct_node" do

    it "builds a Node instance" do
      chain = markov_builder_class.new
      nodes = chain.nodes
      expect(node_class).to(
        receive(:new).with(value: "foo", nodes: nodes).and_call_original
      )
      node = chain.construct_node("foo")
      expect(node).to be_a node_class
      expect(node.nodes).to eq nodes
      expect(node.value).to eq "foo"
    end

  end

  describe "#add_linkages" do
    it "calls add_next_linkage on node1 with the mirror_change flag" do
      chain = markov_builder_class.new
      node1, node2 = %w{foo bar}.map &chain.method(:construct_node)
      expect(node1).to receive(:add_next_linkage).with(node2, true)
      chain.add_linkages node1, node2 
    end
  end

  describe "#evaluate" do

    around(:each) do |example|
      srand(0) # seeds the randomness 
      example.run
      srand() # unseeds the randomness
    end

    it "evaluates the chain into a random order" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      results = 3.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
        "bat in the hat cat",
        "flat the bat in the",
        "the flat flat cat in"
      ]
    end

  end

end