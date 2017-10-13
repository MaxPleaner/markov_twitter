class MarkovTwitter::MarkovBuilder

  # Represents a single node in a Markov chain
  class Node

    # @attr value [String] a single token, e.g. a word
    # @attr linkages [Hash<String, Hash<String, Float>>]
    #   - Outer hash is keyed by the string value.
    #     Inner hash represents possible traversals -
    #     also keyed by string value, its values are probabilities
    #     representing the likelihood of choosing that route.
    # @attr num_inputs_per_cell [Hash<Symbol, Hash<String,Integer>>]
    #   - incremented/decremented whenever a linkage is added/removed
    #   - used to re-calculate probabilities.
    # @attr total_num_inputs [Hash<Symbol>, Integer]
    #    - also used to re-calculate probabilities
    attr_reader :value, :linkages, :num_inputs_per_cell, :total_num_inputs
    
    # @keyword value [String]
    def initialize(value: nil)
      @value = value
      @linkages = { next: Hash.new(0), prev: Hash.new(0) }
      @num_inputs_per_cell = { next: Hash.new(0), prev: Hash.new(0) }
      @total_num_inputs = { next: 0, prev: 0 }
    end

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

    # If a Nth item is inserted into the linkages at <direction>,
    # then the weight of a single insertion is re-calculated to 1/N
    def get_probability_unit(direction)
      1.0 / total_num_inputs[direction]
    end

    # a check made before removing a node, to ensure the state remains valid.
    def preempt_faulty_removal(direction, other_node)
      if [
        total_num_inputs[direction],
        num_inputs_per_cell[direction][other_node.value]
      ].any? { |val| val == 0 }
        raise ArgumentError("can't remove what does not exist.")
      end
    end

    # @param direction [Symbol] either :next or :prev
    # @param other_node [Node]
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

    # @param child_node [Node] to be added to the :next linkage
    # @return void
    def add_next_linkage(child_node)
      add_and_adjust_probabilities(:next, child_node)
    end
 
    # @param parent_node [Node] to be added to the :prev linkage
    # @return void
    def add_prev_linkage(parent_node)
      add_and_adjust_probabilities(:prev, parent_node)
    end

    # @param child_node [Node]
    # @return void
    def remove_next_linkage(child_node)
      remove_and_adjust_probabilities(:next, child_node)
    end

    # @param parent_node [Node]
    # @return void
    def remove_prev_linkage(parent_node)
      remove_and_adjust_probabilities(:prev, parent_node)
    end


  end

end