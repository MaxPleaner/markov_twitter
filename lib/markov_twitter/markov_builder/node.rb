class MarkovTwitter::MarkovBuilder

  # Represents a single node in a Markov chain
  class Node

    # @!attribute [r] value
    #   return [String] a single token, e.g. a word
    #
    # @!attribute [r] linkages
    #   return [Hash<Symbol, Hash<String, Float>>]
    #   - Outer hash is keyed by the direction (:next, :prev).
    #   - Inner hash represents possible traversals -
    #     also keyed by string value, its values are probabilities
    #     representing the likelihood of choosing that route.
    #
    # @!attribute [r] num_inputs_per_cell
    #   return [Hash<Symbol, Hash<String,Integer>>]
    #   - outer hash is keyed by the direction (:next, :prev)
    #   - inner hash is keyed by node value and the Integer value is
    #     incremented/decremented whenever a linkage is added/removed
    #   - used to re-calculate probabilities.
    #
    # @!attribute [r] total_num_inputs
    #   return [Hash<Symbol>, Integer]
    #    - tracks the total number of inputs added in a direction
    #    - also used to re-calculate probabilities
    #
    attr_reader :value, :linkages, :num_inputs_per_cell, :total_num_inputs
    
    # @param value [String] for example, a word
    def initialize(value: nil)
      @value = value
      @linkages = { next: Hash.new(0), prev: Hash.new(0) }
      @num_inputs_per_cell = { next: Hash.new(0), prev: Hash.new(0) }
      @total_num_inputs = { next: 0, prev: 0 }
    end

    # Adds a single node to the :next linkages and updates probabilities
    # @param direction [Symbol] either :next or :prev
    # @param other_node [Node]
    # @return void
    def add_and_adjust_probabilities(direction, other_node)
      total_num_inputs[direction] == 0
      total_num_inputs[direction] += 1
      probability_unit = get_probability_unit(direction)
      num_inputs_per_cell[direction][other_node.value] += 1
      num_inputs_per_cell[direction].each_key do |node_key|
        linkages[direction][node_key] = (
          num_inputs_per_cell[direction][node_key] * probability_unit
        )
      end
    end

    # Determines the weight of a single insertion by looking up the total
    # number of insertions in that direction.
    # @param direction [Symbol] :next or :prev
    # @return [Float] between 0 and 1
    def get_probability_unit(direction)
      1.0 / total_num_inputs[direction]
    end

    # a check made before removing a node, to ensure the state remains valid.
    # @param direction [Symbol] :next or :prev
    # @param other_node [Node] the node to be removed
    # @return void
    def preempt_faulty_removal(direction, other_node)
      if [
        total_num_inputs[direction],
        num_inputs_per_cell[direction][other_node.value]
      ].any? { |val| val == 0 }
        raise ArgumentError("can't remove what does not exist.")
      end
    end

    # Removes a single node from the :prev linkages and updates probabilities
    # @param direction [Symbol] either :next or :prev
    # @param other_node [Node] the node to be removed
    # @return void
    def remove_and_adjust_probabilites(direction, other_node)
      preempt_faulty_removal
      total_num_inputs[direction] -= 1
      num_inputs_per_cell[direction][other_node.value] -= 1
      if num_inputs_per_cell[direction][other_node.value] == 0
        linkages[direction].delete(other_node.value)
        num_inputs_per_cell[direction].delete(other_node.value)
      end
      probability_unit = get_probability_unit(direction)
      num_inputs_per_cell[direction].each_key do |node_key|
        linkages[direction][node_key] = (
          num_inputs_per_cell[direction][node_key] * probability_unit
        )
      end
    end

    # Adds another node to the :next linkages, updating probabilities
    # @param child_node [Node] to be added
    # @return void
    def add_next_linkage(child_node)
      add_and_adjust_probabilities(:next, child_node)
    end
 
    # Adds another node to the :prev linkages, updating probabilities
    # @param parent_node [Node] to be added
    # @return void
    def add_prev_linkage(parent_node)
      add_and_adjust_probabilities(:prev, parent_node)
    end

    # Removes a node from the :next linkages, updating probabilities
    # @param child_node [Node] to be removed
    # @return void
    def remove_next_linkage(child_node)
      remove_and_adjust_probabilities(:next, child_node)
    end

    # Removes a node from the :prev linkages, updating probabilities
    # @param parent_node [Node] to be removed.
    # @return void
    def remove_prev_linkage(parent_node)
      remove_and_adjust_probabilities(:prev, parent_node)
    end

  end

end