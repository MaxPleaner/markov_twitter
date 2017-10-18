
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

  around(:each) do |example|
    srand(0) # seeds the randomness 
    example.run
    srand() # unseeds the randomness
  end

  describe "#initialize" do

    it "processes phrases and stores their values/linkages" do
      chain = markov_builder_class.new(phrases: sample_phrases)
      nodes = chain.nodes
      expect(nodes.keys.sort).to eq(%w{bat cat flat hat in the})
      validate_linkages(nodes["in"],
        _next: {"the" => 1},
        prev: {"cat" => 0.5, "bat" => 0.5},
        total_num_inputs: { next: 2, prev: 2}
      )
      validate_linkages(nodes["the"],
        _next: {"cat" => 0.25, "bat" => 0.25, "hat" => 0.25, "flat" => 0.25},
        prev: {"in" => 1.0},
        total_num_inputs: { next: 4, prev: 2}
      )
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

    context "without a specified start node" do

      it "starts from a random node" do
        chain = markov_builder_class.new(phrases: ["foo"])
        node_finder = chain.node_finders[:random]
        expect(chain).to(
          receive(:get_new_start_point)
          .exactly(3).times
          .with(node_finder)
          .and_call_original
        )
        expect(chain.evaluate(length: 3)).to eq("foo foo foo")
      end

    end

    context "with a specified start node" do

      it "starts at the given node" do
        chain = markov_builder_class.new phrases: ["foo bar bar"]
        expect(chain).not_to(receive(:get_new_start_point))
        expect(chain.evaluate(
          length: 5,
          root_node: chain.nodes["bar"]
        )).to eq ("bar bar bar bar bar")
      end

    end

    context "with a specified probability_bounds" do

      it "can prioritize less-likely options" do
        chain = markov_builder_class.new phrases: ["a b a a a a a"]
        expect(3.times.map do
          chain.evaluate(
            length: 7,
            probability_bounds: [0, 20]
          )
        end).to eq([
          "b a b a b a b",
          "a b a b a b a",
          "a b a b a b a"
        ])
      end

      it "can prioritze more-likely options" do
        chain = markov_builder_class.new phrases: ["a b a a a"]
        expect(10.times.map do
          chain.evaluate(
            length: 10,
            probability_bounds: [34, 100]
          )
        end).to eq([
          "b a a a a a a a a a",
          "b a a a a a a a a a",
          "b a a a a a a a a a",
          "b a a a a a a a a a",
          "b a a a a a a a a a",
          "a a a a a a a a a a",
          "a a a a a a a a a a",
          "b a a a a a a a a a",
          "a a a a a a a a a a",
          "b a a a a a a a a a"
        ])
      end

    end

    context "default behavior" do

      it "handles punctuation like any other character" do
        chain = markov_builder_class.new phrases: ["a. cat! in, a; hat - (sat)"]
        expect(3.times.map { chain.evaluate length: 5 }).to eq([
          "(sat) cat! in, a; hat",
          "in, a; hat - (sat)",
          "hat - (sat) - (sat)"
        ])
      end

    end

  end

  describe "_evaluate" do

    context "evaluating forwards" do

      it "can use an arbitrary filter to find starting nodes" do
        chain = markov_builder_class.new phrases: sample_phrases
        expect(3.times.map do
          chain._evaluate(
            length: 5,
            direction: :next,
            node_finder: -> (node) {
              # every phrase in the results should start with cat.
              node.value == "cat"
            }
          ).map(&:value).join(" ")
        end).to eq([
          "cat in the flat cat",
          "cat in the cat in",
          "cat in the cat in"
        ])
      end

    end

    context "evaluating backwards" do

      it "can use an arbitrary filter to find start nodes" do
        # The "start nodes" determine the ending of the phrases
        # in this case, since the result is reversed and traversal
        # happens along :prev linkages
        chain = markov_builder_class.new phrases: sample_phrases
        expect(3.times.map do
          chain._evaluate(
            length: 5,
            direction: :prev,
            node_finder: -> (node) {
              # every phrase in the results should end with hat
              node.value == "hat"
            }
          ).map(&:value).reverse.join(" ")
        end).to eq([
          "the bat in the hat",
          "the cat in the hat",
          "the bat in the hat"
        ])
      end

    end

  end

  describe "#evaluate_favoring_start" do

    it "ensures the result's start nodes are also start nodes in the input" do
      chain = markov_builder_class.new phrases: sample_phrases
      node_finder = chain.node_finders[:favor_start]
      expect(chain).to receive(:_evaluate).with(
        length: 5,
        probability_bounds: [0,100],
        root_node: nil,
        direction: :next,
        node_finder: node_finder
      ).exactly(3).and_call_original
      expect(3.times.map do
        chain.evaluate_favoring_start length: 5
      end).to eq([
        "the cat in the bat",
        "the hat the bat in",
        "the flat the hat the"
      ])
    end

  end

  describe "#evaluate_favoring_end" do

    it "works" do
      chain = markov_builder_class.new phrases: sample_phrases
      node_finder = chain.node_finders[:favor_end]
      expect(chain).to receive(:_evaluate).with(
        length: 5,
        probability_bounds: [0,100],
        root_node: nil,
        direction: :prev,
        node_finder: node_finder
      ).exactly(3).times.and_call_original
      expect(3.times.map do
        chain.evaluate_favoring_end length: 5
      end).to eq([
        "the bat in the flat",
        "the cat in the hat",
        "the bat in the hat"
      ])
    end

  end

  describe "#get_new_start_point" do

    it "returns a random one that satisfies the criteria" do
      chain = markov_builder_class.new phrases: sample_phrases
      # all phrases will start with "in"
      node_finder = -> (node) { node.value == "in" }
      vals = chain.nodes.values
      shuffled = chain.nodes.values.shuffle
      expect(chain.nodes).to(
        receive(:values).exactly(3).times.and_return vals
      )
      expect(vals).to(
        receive(:shuffle).exactly(3).times.and_return shuffled
      )
      # thanks to https://stackoverflow.com/a/28419381/2981429
      # for the tip on how to do this
      expect(shuffled).to(
        receive(:find).with(no_args) do |blk|
          expect(blk).to eq(node_finder)
        end.exactly(3).times.and_call_original
      )
      expect(3.times.map do
        chain.get_new_start_point node_finder
      end.map(&:value)).to eq(%w{in in in})
    end
  
  end

  describe "#pick_linkage" do

    context "default probability_bounds" do

      it "picks the next linkage according to the probabilities" do
        chain = markov_builder_class.new phrases: ["a b", "a c", "a b"]
        a,b,c = chain.nodes.values_at *%w{a b c}
        # the lower-prob option "b" can be excluded
        expect(
          chain.pick_linkage(a.linkages[:next], [34, 100])
        ).to eq(b)
        # similarly, the higher-prob option "c" can be excluded
        expect(
          chain.pick_linkage(a.linkages[:next], [0, 33])
        ).to eq(c)
      end

      it "returns nil if there are no options" do
        chain = markov_builder_class.new phrases: []
        expect(chain.pick_linkage([])).to be_nil
      end

    end

  end

end