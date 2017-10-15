using MarkovTwitter::TestHelperMethods

RSpec.describe "Node" do

  let(:phrase1) { get_sample_phrase_1 }
  let(:phrase2) { get_sample_phrase_2 }
  let(:sample_phrases) { [phrase1, phrase2] }
  let(:markov_builder) { MarkovTwitter::MarkovBuilder }

  around(:each) do |example|
    srand(0) # seeds the randomness 
    example.run
    srand() # unseeds the randomness
  end

  describe "#add_next_linkage" do

    it "can add a :next option more probable by adding it multiple times" do
      chain = markov_builder.new(phrases: sample_phrases)
      the = chain.nodes["the"]
      cat = chain.nodes["cat"]
      bat = chain.nodes["bat"]
      # make the => bat => cat very probable
      20.times { the.add_next_linkage bat }
      20.times { bat.add_next_linkage cat }
      results = 3.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
       "bat cat in the bat",
       "hat in the bat cat",
       "the bat cat in the"
      ]
    end

    it "can add a recursive :next option pointing to itself" do
      chain = markov_builder.new(phrases: sample_phrases)
      the = chain.nodes["the"]
      # make the => the very probable
      20.times { the.add_next_linkage the }
      results = 3.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
        "bat in the the the",
        "hat in the the bat",
        "cat in the the cat"
      ]
    end

  end

  describe "#remove_next_linkage" do

    it "can remove a certain word to make it less likely" do
      chain = markov_builder.new(phrases: sample_phrases)
      the, cat, bat, hat = chain.nodes.values_at *%w{the cat bat hat}
      # make the => cat/bat/hat impossible.
      %w{cat bat hat}.each do |word|
        # it's safe to run remove_next_linkage excess times.
        5.times do
          the.remove_next_linkage chain.nodes[word]
        end
      end
      results = 3.times.map { chain.evaluate(length: 5) }
      expect(results).to eq [
        "bat in the flat cat",
        "flat the flat in the",
        "the flat cat in the"
      ]
    end

  end

  describe "#delete_linkage!" do

    it "can remove a node as an option entirely" do
      chain = markov_builder.new(phrases: sample_phrases)
      the, cat, bat, hat = chain.nodes.values_at *%w{the cat bat hat}
      # make the => cat/bat/hat impossible.
      # it's safe to run delete_linkage! excess times.
      %w{cat bat hat}.each do |word|
        5.times do
          the.delete_linkage! :next, chain.nodes[word]
        end
      end
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
      chain = markov_builder.new(phrases: sample_phrases)
      the, flat = chain.nodes.values_at *%w{the flat}
      # set "flat" to 0.5, adjusting all the others
      the.add_linkage!(:next, flat, 0.5)
      validate_linkages(the, _next: {
        "flat" => 0.5,
        "cat" => 0.5 / 3,
        "bat" => 0.5 / 3,
        "hat" => 0.5 / 3
      })
      # set "flat" to 1, removing all others
      the.add_linkage!(:next, flat, 1)
      validate_linkages(the, _next: {
        "flat" => 1
      })
    end

  end
  
end