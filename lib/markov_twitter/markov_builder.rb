# Builds a Markov chain from phrases passed as input.
# A "phrase" is defined here as a tweet.
class MarkovTwitter::MarkovBuilder

  # Regex used to split the phrase into tokens.
  # It splits on any number of whitespace\in sequence.
  # Sequences of punctuation characters are treated like any other word.
  SeparatorCharacterRegex = /\s+/

  # @return [Hash<String, Node>]
  # The base dictionary for nodes.
  # There is only a single copy of each node created,
  # although they are referenced in Node#linkages as well.
  attr_reader :nodes

  # Splits a phrase into tokens.
  # @param phrase [String]
  # @return [Array<String>]
  def self.split_phrase(phrase)
    phrase.split(SeparatorCharacterRegex)
  end

  # @param phrases [Array<String>] e.g. sentences or tweets.
  # processes the phrases to populate @nodes.
  def initialize(phrases: [])
    @nodes = {}
    phrases.each &method(:process_phrase)
  end

  # Splits a phrase into tokens, adds them to @nodes, and creates linkages.
  # @param phrase [String] e.g. a sentence or tweet.
  # @return [void]
  def process_phrase(phrase)
    node_vals = self.class.split_phrase(phrase)
    node_vals.length.times do |i|
      nodes = node_vals[i..(i+1)].compact.map do |node_val|
        construct_node(node_val)
      end
      add_nodes(*nodes)
    end
  end

  # Adds a sequence of two tokens to @nodes and creates linkages.
  # if node_val2 is nil, it won't be added and linkages won't be created
  # @param node1 [Node]
  # @param node2 [Node]
  # @return [void]
  def add_nodes(node1, node2=nil)
    unless node1.is_a?(Node)
      raise ArgumentError, "first arg passed to add_nodes is not a Node"
    end
    @nodes[node1.value] ||= node1
    if node2
      @nodes[node2.value] ||= node2
      add_linkages(*@nodes.values_at(*[node1,node2].map(&:value)))
    end
  end

  # Builds a single node which contains a reference to @nodes.
  # Note that this does do the inverse (it doesn't add the node to @nodes)
  # @param value [String]
  def construct_node(value)
    Node.new(value: value, nodes: @nodes)
  end

  # Adds bidirectional linkages beween two nodes.
  # the Node class re-calculates the probabilities internally.
  # @param node1 [Node] the parent.
  # @param node2 [Node] the child.
  # @return [void]
  def add_linkages(node1, node2)
    # raise an error unless node1 is a node.
    # Mirrors the change on :prev 
    node1.add_next_linkage(node2, mirror_change=true)
  end

  # An "evaluation" of the markov chain. e.g. a run case.
  # Passes random values through the probability sequences.
  # @param length [Integer] the number of tokens in the result.
  # @return [String], the resulting tokens joined by a whitespace.
  def evaluate(length:)
    root_node = nil
    length.times.reduce([]) do |result_nodes|
      root_node ||= get_new_start_point(@nodes.keys)
      result_nodes.push root_node
      root_node = pick_linkage(root_node.linkages[:next])
      result_nodes
    end.map(&:value).join(" ")
  end

  # Gets a random node as a potential start point.
  # @param linkage_names [Array<String>]
  # @return [Node] or nil if one couldn't be found.
  def get_new_start_point(linkage_names)
    nodes[linkage_names.sample]
  end

  # Given "linkages" which includes all possibly node traversals in
  # a predetermined direction, pick one based on their probabilities.
  # @param linkages [Hash<String, Float>] key=token, val=probability
  # @return [Node] or nil if one couldn't be found.
  def pick_linkage(linkages)
    random_num = rand(100) * 0.01
    offset = 0
    new_key = linkages.keys.find do |key|
      probability = linkages[key]
      is_match = random_num.between?(offset, probability)
      offset += probability
      is_match
    end
    nodes[new_key]
  end


end