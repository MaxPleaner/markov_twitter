class MarkovTwitter::MarkovBuilder

  # Represents a single node in a Markov chain.
  class Node

    # @return [String] a single token, such as a word.
    attr_reader :value

    # @return [Hash<Symbol, Hash<String, Float>>]
    #   the :next and :previous linkages.
    #   - Outer hash is keyed by the direction (:next, :prev).
    #   - Inner hash represents possible traversals -
    #     also keyed by string value, its values are probabilities
    #     representing the likelihood of choosing that route.
    attr_reader :linkages

    # @return [Hash<Symbol>, Integer]
    #   the total number of inputs added in each direction.
    #   - also used to re-calculate probabilities.
    attr_reader :total_num_inputs

    # @return [Hash<String,Node>]
    #   a reference to the attr of the parent MarkovBuilder
    attr_reader :nodes
    
    # @param value [String] for example, a word.
    # @param nodes [Hash<String,Node>].
    def initialize(value:, nodes:)
      @value = value
      @linkages = { next: Hash.new(0), prev: Hash.new(0) }
      @num_inputs_per_cell = { next: Hash.new(0), prev: Hash.new(0) }
      @total_num_inputs = { next: 0, prev: 0 }
      @nodes = nodes
    end

    # Adds a single node to the :next linkages and updates probabilities.
    # Also updates the opposite direction,
    # e.g. :prev will be updated if something is added to :next.
    # @param direction [Symbol] either :next or :prev.
    # @param other_node [Node]
    # @param mirror_change [Boolean] 
    #   whether to update the opposite direction, defaults to true.
    # @return [void]
    def add_and_adjust_probabilities(direction, other_node, mirror_change=true)
      @nodes[other_node.value] ||= other_node
      total_num_inputs[direction] += 1
      unit = get_probability_unit(direction)
      probability_multiplier = (total_num_inputs[direction] - 1) * unit
      linkages[direction].each_key do |node_key|
        linkages[direction][node_key] *= probability_multiplier
      end
      linkages[direction][other_node.value] += unit
      # Add a linkage in the opposite direction to keep :next and :prev in sync
      update_opposite_direction(direction, other_node, __method__) if mirror_change
    end

    # Determines the weight of a single insertion by looking up the total
    # number of insertions in that direction.
    # @param direction [Symbol] :next or :prev
    # @return [Float] between 0 and 1.
    def get_probability_unit(direction)
      1.0 / total_num_inputs[direction]
    end

    # Removes a single node from the :prev linkages and updates probabilities.
    # Safe to run if the other_node is not actually present in the linkages.
    # Mirrors the change in the opposite direction, to keep :prev and :next in sync.
    # @param direction [Symbol] either :next or :prev
    # @param other_node [Node] the node to be removed.
    # @param mirror_change [Boolean]
    #   whether to update the opposite direction, defaults to true
    # @return [void]
    def remove_and_adjust_probabilities(direction, other_node, mirror_change=true)
      return unless linkages[direction].has_key? other_node.value
      unit = get_probability_unit(direction)
      if linkages[direction][other_node.value] - unit <= 0
        delete_linkage!(direction, other_node)
      else
        linkages[direction][other_node.value] -= unit
        num_per_direction = total_num_inputs[direction]
        linkages[direction].each_key do |node_key|
          linkages[direction][node_key] *= (
            num_per_direction / (num_per_direction - 1.0)
          )
        end
        total_num_inputs[direction] -= 1
      end
      # Add a linkage in the opposite direction to keep :next and :prev in sync
      update_opposite_direction(direction, other_node, __method__) if mirror_change
    end

    # Force-removes a linkage, re-adjusting other probabilities
    # but potentially breaking their proportionality.
    # Can be safely run for non-existing nodes.
    # Adjusts the linkages in the opposite direction accordingly.
    # @param direction [Symbol]
    # @param other_node [Node]
    # @param mirror_change [Boolean]
    #   whether to update the opposite direction, defaults to true
    # @return [void]
    def delete_linkage!(direction, other_node, mirror_change=true)
      return unless linkages[direction].has_key? other_node.value
      probability = linkages[direction][other_node.value]
      # delete the linkage
      linkages[direction].delete other_node.value
      # distribute the probability evenly among the other options.
      amt_to_add = probability / linkages[direction].keys.length
      linkages[direction].each_key do |key|
        linkages[direction][key] += amt_to_add
      end
      # decrement the total count
      total_num_inputs[direction] -= 1
      # Add a linkage in the opposite direction to keep :next and :prev in sync      
      update_opposite_direction(direction, other_node, __method__) if mirror_change
    end

    # Force-adds a linkage at a specific probability.
    # Readjusts other probabilities but may break their proportionality.
    # Updates the opposite direction to keep :next and :prev in sync
    # @param direction [Symbol]
    # @param other_node [Node]
    # @param probability [Float] between 0 and 1.
    # @param mirror_change [Boolean] whether to update the opposite direction.
    # @return [void]
    def add_linkage!(direction, other_node, probability, mirror_change=true)
      raise ArgumentError, "invalid probability" unless probability.between?(0,1)
      # first remove any existing node there and distribute the probability.
      delete_linkage!(direction, other_node)
      # Re-adjust each probability to account for the added value
      linkages[direction].each_key do |key|
        linkages[direction][key] *= (1 - probability)
        # remove the linkage if it's probability is zero
        if linkages[direction][key].zero?
          delete_linkage!(direction, @nodes[key])
        end
      end
      # Add the new value and set its probability
      linkages[direction][other_node.value] = probability
      # increment the total count
      total_num_inputs[direction] += 1
      # Add a linkage in the opposite direction to keep :next and :prev in sync      
      if mirror_change
        update_opposite_direction(direction, other_node, __method__, probability)
      end
    end

    # Calls given method_name on other_node, passing the opposite direction
    # to the one given as an argument. This keeps :next and :prev in sync.
    # @param direction [Symbol]
    #   something should have already been added/removed here
    # @param other_node [Node] the node which was added/removed
    # @param method_name [Symbol] the method to invoke on other_node
    # @return [void]
    def update_opposite_direction(direction, other_node, method_name, *other_args)
      other_direction = (%i{next prev} - [direction])[0]
      other_node.send(method_name, other_direction, self, *other_args, false)
    end

    # Adds another node to the :next linkages, updating probabilities.
    # @param child_node [Node] to be added.
    # @return [void]
    def add_next_linkage(child_node, mirror_change=true)
      add_and_adjust_probabilities(:next, child_node)
    end
 
    # Adds another node to the :prev linkages, updating probabilities.
    # @param parent_node [Node] to be added.
    # @return [void]
    def add_prev_linkage(parent_node, mirror_change=true)
      add_and_adjust_probabilities(:prev, parent_node)
    end

    # Removes a node from the :next linkages, updating probabilities.
    # @param child_node [Node] to be removed.
    # @return [void]
    def remove_next_linkage(child_node, mirror_change=true)
      remove_and_adjust_probabilities(:next, child_node)
    end

    # Removes a node from the :prev linkages, updating probabilities.
    # @param parent_node [Node] to be removed.
    # @return [void]
    def remove_prev_linkage(parent_node, mirror_change=true)
      remove_and_adjust_probabilities(:prev, parent_node)
    end

  end

end