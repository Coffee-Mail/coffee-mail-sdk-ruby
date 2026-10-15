# frozen_string_literal: true

module RuboCop
  module Cop
    module CoffeeMail
      class NoElse < Base
        MSG = "else/elsif são proibidos. Use retorno antecipado ou uma tabela de lookup."

        def on_if(node)
          return if node.ternary?
          return unless node.else?
          return if node.elsif?

          add_offense(node.loc.else)
        end

        def on_rescue(node)
          return unless node.else?

          add_offense(node.loc.else)
        end
      end
    end
  end
end
