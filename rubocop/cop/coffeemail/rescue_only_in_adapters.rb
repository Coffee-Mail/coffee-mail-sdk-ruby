# frozen_string_literal: true

module RuboCop
  module Cop
    module CoffeeMail
      class RescueOnlyInAdapters < Base
        MSG = "rescue/raise só nos adaptadores isolados (AllowedFiles). Devolva o erro no envelope."
        RAISING_METHODS = %i[raise fail].freeze

        def on_resbody(node)
          return if allowed_file?

          add_offense(node.loc.keyword)
        end

        def on_send(node)
          return unless node.receiver.nil? && RAISING_METHODS.include?(node.method_name)
          return if allowed_file?

          add_offense(node.loc.selector)
        end

        private

        def allowed_file?
          path = processed_source.file_path.to_s
          cop_config.fetch("AllowedFiles", []).any? { |allowed| path.end_with?(allowed) }
        end
      end
    end
  end
end
