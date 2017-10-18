# Builds a Markov chain from phrases passed as input.
# A "phrase" is defined here as a tweet.
class MarkovTwitter::MarkovBuilder

  # Regex used to split the phrase into tokens.
  # It splits on any number of whitespace\in sequence.
  # Sequences of punctuation characters are treated like any other word.
  SeparatorCharacterRegex = /\s+/

  # The base dictionary for nodes.
  # There is only a single copy of each node created,
  # although they are referenced in Node#linkages as well.
  # @return [Hash<String, Node>]
  attr_reader :nodes

  # The nodes that were found at the start of phrases
  # @return [Set<Node>]
  attr_reader :start_nodes

  # The nodes that were found at the end of phrases
  # @return [Set<Node>]
  attr_reader :end_nodes

  def node_finders
    @node_finders ||= {
      random:      -> (node) { true },
      favor_start: -> (node) { start_nodes.include? node.value },
      favor_end:   -> (node) { end_nodes.include? node.value },
    }
  end

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
    @start_nodes = Set.new
    @end_nodes = Set.new
    phrases.each &method(:process_phrase)
  end

  # Splits a phrase into tokens, adds them to @nodes, and creates linkages.
  # @param phrase [String] e.g. a sentence or tweet.
  # @return [void]
  def process_phrase(phrase)
    node_vals = self.class.split_phrase(phrase)
    last_node = nil
    node_vals.length.times do |i|
      nodes = node_vals[i..(i+1)].compact.map do |node_val|
        construct_node(node_val)
      end
      @start_nodes.add(nodes[0].value) if i == 0
      last_node = nodes.last
      add_nodes(*nodes)
    end
    @end_nodes.add last_node.value
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
  # @return [Node]
  def construct_node(value)
    Node.new(value: value, nodes: @nodes)
  end

  # Adds bidirectional linkages beween two nodes.
  # the Node class re-calculates the probabilities internally
  # and mirrors the change on :prev.
  # @param node1 [Node] the parent.
  # @param node2 [Node] the child.
  # @return [void]
  def add_linkages(node1, node2)
    node1.add_next_linkage(node2, mirror_change=true)
  end

  # The default evaluation method to produce a run case.
  # Goes in forward direction with with random nodes as start points.
  # See also #evaluate_favoring_start and #evaluate_favoring_end.
  # See #_evaluate for paramspecs
  # The passed node_node_finder lambda picks a totally random new node.
  # @return [String] the result of #_evaluate joined by whitespace.
  def evaluate(length:, probability_bounds: [0,100], root_node: nil)
    _evaluate(
      length: length,
      probability_bounds: probability_bounds,
      root_node: root_node,
      direction: :next,
      new_node_finder: node_finders[:random]
    ).map(&:value).join(" ")
  end

  # See #_evaluate for paramspec.
  # The passed node_node_finder lambda picks a node contained in @start_nodes
  # An error is raised if no nodes match this condition.
  # @return [String] the result of #_evaluate joined by whitespace.
  def evaluate_favoring_start(length:, probability_bounds: [0,100], root_node: nil)
    new_node_finder = node_finders[:favor_start]
    has_possible_start_node = nodes.values.any? &new_node_finder
    unless has_possible_start_node
      raise ArgumentError, "@start_nodes is empty; can't evaluate favoring start"
    end
    _evaluate(
      length: length,
      probability_bounds: probability_bounds,
      root_node: root_node,
      direction: :next,
      new_node_finder: new_node_finder
    ).map(&:value).join(" ")
  end

  # See #_evaluate for paramspec.
  # The passed node_node_finder lambda picks a node contained in @end_nodes
  # An error is raised if no nodes match this condition.
  # @return [String] the result of #_evaluate reversed and joined by whitespace.
  def evaluate_favoring_end(length:, probability_bounds: [0,100], root_node: nil)
    new_node_finder = node_finders[:favor_end]
    has_possible_end_node = nodes.values.any? &new_node_finder
    unless has_possible_end_node
      raise ArgumentError, "@end_nodes is empty; can't evaluate favoring end"
    end
    _evaluate(
      length: length,
      probability_bounds: probability_bounds,
      root_node: root_node,
      direction: :prev,
      new_node_finder: new_node_finder
    ).map(&:value).reverse.join(" ")
  end

  # An "evaluation" of the markov chain. e.g. a run case.
  # Passes random values through the probability sequences.
  # @param length [Integer] the number of tokens in the result.
  # @param probability_bounds [Array<Integer, Integer>]
  #   optional, can limit the probability to a range where
  #   0 <= min <= result <= max <= 100.
  # @param new_node_finder [Lambda<Node>]
  #   during iteration, if the current node has no linkages in <direction>,
  #   a new node is selected from the nodes dict. The first randomly-picked
  #   node which this lambda returns a truthy value for is selected.
  # @return [Array<Node>] the result tokens in order.
  def _evaluate(
    length:,
    probability_bounds: [0,100],
    root_node: nil,
    direction:,
    new_node_finder:
  )
    length.times.reduce([]) do |result_nodes|
      root_node ||= get_new_start_point(new_node_finder)
      result_nodes.push root_node
      root_node = pick_linkage(
        root_node.linkages[direction],
        probability_bounds,
      )
      result_nodes
    end
  end

  # Gets a random node as a potential start point.
  # @param new_node_finder [lambda<Node>]
  #   any returned node will return a truthy value from this.
  # @return [Node] or nil if one couldn't be found.
  def get_new_start_point(new_node_finder)
    nodes.values.shuffle.find(&new_node_finder)
  end

  # validates the given probability bounds
  # @param bounds [Array<Integer, Integer>]
  # @return [Boolean] indicating whether it is valid
  def check_probability_bounds(bounds)
    bounds1, bounds2 = bounds
    bounds_diff = bounds2 - bounds1 
    if (
      (bounds_diff < 0) || (bounds_diff > 100) ||
      (bounds1 < 0) || (bounds2 > 100)
    )
      raise ArgumentError, "wasn't given 0 <= bounds1 <= bounds2 <= 100"
    end
  end

  # Given "linkages" which includes all possibly node traversals in
  # a predetermined direction, pick one based on their probabilities.
  # @param linkages [Hash<String, Float>] key=token, val=probability
  # @param probability_bounds [Array<Integer,Integer>]
  #   Optional, can limit the probability to a range where
  #   0 <= min <= result <= max <= 100.
  #   This gets divided by 100 before being compared to the linkage values.
  #   
  # @return [Node] or nil if one couldn't be found.
  def pick_linkage(linkages, probability_bounds=[0,100])
    check_probability_bounds(probability_bounds)
    bounds1, bounds2 = probability_bounds
    # pick a random number between the bounds.
    random_num = (rand(bounds2 - bounds1) + bounds1) * 0.01
    # offset is the accumulation of probabilities seen during iteration.
    offset = 0
    # sort to lowest first
    sorted = linkages.sort_by { |name, prob| prob }
    # find the first linkage value that satisfies offset < N(rand) < val.
    new_key = sorted.find do |(key, probability)|
      # increment the offset each time.
      random_num.between?(offset, probability + offset).tap do
        offset += probability
      end
    end
    nodes[new_key&.first]
  end

end