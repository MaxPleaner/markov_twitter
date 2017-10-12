class MarkovTwitter::MarkovBuilder

  SeparatorCharacterRegex = /[\s\.]+?/

  # Represents a single node in a Markov chain
  class Node
    attr_reader :value, :linkages
    def initialize(value: nil)
      @value = value
      @linkages = { next: [], prev: [] }
    end
  end

  attr_reader :nodes

  def initialize(phrases:)
    @nodes = {}
    phrases.each &method(:process_phrase)
  end

  def process_phrase(phrase)
    node_vals = split_and_sanitize_phrase(phrase)
    node_vals.length.times do |i|
      node_val1 = node_vals[i]
      node_val2 = node_vals[i + 1]
      @nodes[node_val1] ||= Node.new(value: node_val1)
      if node_val2
        @nodes[node_val2] ||= Node.new(value: node_val2)
        node1 = @nodes[node_val1]
        node2 = @nodes[node_val2]
        node1.linkages[:next].push node2
        node2.linkages[:prev].push node1
      end
    end
  end

  # Evaluates the nodes & linkages to make a new sentence
  def evaluate(length:)
    root_node = nil
    length.times.reduce([]) do |result_nodes|
      root_node ||= @nodes.values.sample
      result_nodes.push root_node
      root_node = root_node.linkages[:next].sample
      result_nodes
    end.map(&:value).join(" ")
  end

  def split_and_sanitize_phrase(phrase)
    regex = self.class::SeparatorCharacterRegex
    phrase.split(regex).map(&:downcase)
  end
  
end