class MarkovTwitter::MarkovBuilder

  # Regex used to split the phrase into tokens
  SeparatorCharacterRegex = /[\s\.]+?/

  attr_reader :nodes

  # @param phrases [Array<String>]
  def initialize(phrases:)
    @nodes = {}
    phrases.each &method(:process_phrase)
  end

  # @param phrase [String]
  # @return void
  def process_phrase(phrase)
    node_vals = split_and_sanitize_phrase(phrase)
    node_vals.length.times do |i|
      add_nodes(node_vals[i], node_vals[i + 1])
    end
  end

  # re-calculates the probabilities
  # @param node_val1 [String]
  # @param node_val2 [String]
  # @return void
  def add_nodes(node_val1, node_val2)
    @nodes[node_val1] ||= Node.new(value: node_val1)
    if node_val2
      @nodes[node_val2] ||= Node.new(value: node_val2)
      add_linkages(@nodes[node_val1], @nodes[node_val2])
    end
  end

  # adds node2 to node1's :next,
  # and node1 to node2's :prev
  # the Node class re-calculates the probabilities internally.
  def add_linkages(node1, node2)
    node1.add_next_linkage(node2)
    node2.add_prev_linkage(node1)
  end

  # Evaluates the nodes & linkages to make a new sentence
  # @keyword length [Integer]
  # @return [String]
  def evaluate(length:)
    root_node = nil
    length.times.reduce([]) do |result_nodes|
      root_node ||= get_new_start_point(@nodes.keys)
      result_nodes.push root_node
      root_node = pick_linkage(root_node.linkages[:next])
      result_nodes
    end.map(&:value).join(" ")
  end

  # gets a random node name as a potential start point
  # @param linkage_names [Array<String>]
  # @return [String] or nil
  def get_new_start_point(linkage_names)
    nodes[linkage_names.sample]
  end

  # a random pick weighed by probability
  # @param linkages [Hash<String, Float>]
  # @return [Node] or nil
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

  # @param phrase [String]
  # @return [Array<String>]
  def split_and_sanitize_phrase(phrase)
    regex = self.class::SeparatorCharacterRegex
    phrase.split(regex).map(&:downcase)
  end

end