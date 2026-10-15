# frozen_string_literal: true

module RuboCop
  module Cop
    module CoffeeMail
      class NoCase < Base
        MSG = "case/when e case/in são proibidos. Use um Hash de lookup ou retorno antecipado."

        def on_case(node)
          add_offense(node.loc.keyword)
        end

        def on_case_match(node)
          add_offense(node.loc.keyword)
        end
      end
    end
  end
end
