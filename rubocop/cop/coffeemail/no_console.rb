# frozen_string_literal: true

module RuboCop
  module Cop
    module CoffeeMail
      class NoConsole < Base
        MSG = "Saída em console é proibida na biblioteca."
        CONSOLE_METHODS = %i[puts print p pp warn printf putc display].freeze
        CONSOLE_GLOBALS = %i[$stdout $stderr].freeze
        CONSOLE_CONSTANTS = %i[STDOUT STDERR].freeze

        def on_send(node)
          return unless node.receiver.nil? && CONSOLE_METHODS.include?(node.method_name)

          add_offense(node.loc.selector)
        end

        def on_gvar(node)
          return unless CONSOLE_GLOBALS.include?(node.children.first)

          add_offense(node)
        end

        def on_const(node)
          return unless node.namespace.nil? && CONSOLE_CONSTANTS.include?(node.short_name)

          add_offense(node)
        end
      end
    end
  end
end
