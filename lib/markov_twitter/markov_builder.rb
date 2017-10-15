# Builds a Markov chain from phrases passed as input.
# A "phrase" is defined here as a tweet.
class MarkovTwitter::MarkovBuilder

  # Regex used to split the phrase into tokens.
  # It splits on any number of whitespace and periods in sequence.
  SeparatorCharacterRegex = /[\s\.]+?/

  # @return [Hash<String, Node>]
  # The base dictionary for nodes.
  # There is only a single copy of each node created,
  # although they are referenced in Node#linkages as well.
  attr_reader :nodes

  # @param phrases [Array<String>] e.g. sentences or tweets.
  # processes the phrases to populate @nodes.
  def initialize(phrases:)
    @nodes = {}
    phrases.each &method(:process_phrase)
  end

  # Splits a phrase into tokens, adds them to @nodes, and creates linkages.
  # @param phrase [String] e.g. a sentence or tweet.
  # @return [void]
  def process_phrase(phrase)
    node_vals = split_and_sanitize_phrase(phrase)
    node_vals.length.times do |i|
      add_nodes(node_vals[i], node_vals[i + 1])
    end
  end

  # Adds a sequence of two tokens to @nodes and creates linkages.
  # @param node_val1 [String]
  # @param node_val2 [String]
  # @return [void]
  def add_nodes(node_val1, node_val2)
    @nodes[node_val1] ||= Node.new(value: node_val1, nodes: @nodes)
    if node_val2
      @nodes[node_val2] ||= Node.new(value: node_val2, nodes: @nodes)
      add_linkages(@nodes[node_val1], @nodes[node_val2])
    end
  end

  # Adds bidirectional linkages beween two nodes.
  # the Node class re-calculates the probabilities internally.
  # @param node1 [Node] the parent.
  # @param node2 [Node] the child.
  # @return [void]
  def add_linkages(node1, node2)
    node1.add_next_linkage(node2)
    node2.add_prev_linkage(node1)
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

  # Splits a phrase into tokens.
  # @param phrase [String]
  # @return [Array<String>]
  def split_and_sanitize_phrase(phrase)
    regex = self.class::SeparatorCharacterRegex
    phrase.split(regex)
  end

end