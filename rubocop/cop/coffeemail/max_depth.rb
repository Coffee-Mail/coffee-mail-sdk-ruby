# frozen_string_literal: true

module RuboCop
  module Cop
    module CoffeeMail
      class MaxDepth < Base
        MSG = "Profundidade %<depth>d excede o máximo de %<max>d. Extraia um método ou use retorno antecipado."
        NESTING_TYPES = %i[if while until for block numblock itblock case case_match kwbegin].freeze

        def on_def(node)
          inspect_body(node)
        end

        def on_defs(node)
          inspect_body(node)
        end

        private

        def inspect_body(node)
          node.each_descendant(*NESTING_TYPES) do |descendant|
            depth = depth_of(descendant, node)
            next unless depth > max_depth
            next if nested_offender?(descendant, node)

            add_offense(descendant, message: format(MSG, depth: depth, max: max_depth))
          end
        end

        def nested_offender?(descendant, root)
          descendant.each_ancestor(*NESTING_TYPES).any? do |ancestor|
            ancestor_inside?(ancestor, root) && depth_of(ancestor, root) > max_depth
          end
        end

        def ancestor_inside?(ancestor, root)
          ancestor.each_ancestor.include?(root)
        end

        def depth_of(node, root)
          chain = [node] + node.each_ancestor.take_while { |ancestor| !ancestor.equal?(root) }
          chain.count { |entry| counts?(entry) }
        end

        def counts?(entry)
          return false unless NESTING_TYPES.include?(entry.type)
          return true unless entry.if_type?

          !entry.ternary? && !entry.modifier_form? && !entry.elsif?
        end

        def max_depth
          cop_config.fetch("Max", 3)
        end
      end
    end
  end
end
