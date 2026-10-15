# frozen_string_literal: true

module CoffeeMail
  module Internal
    module Enum
      module_function

      def define(owner, values)
        values.each { |value| owner.const_set(constant_name(value), value.dup.freeze) }
        owner.const_set(:ALL, values.map(&:freeze).freeze)
        owner
      end

      def constant_name(value)
        value.gsub(/([a-z])([A-Z])/, '\1_\2').gsub(/[^A-Za-z0-9]+/, "_").upcase
      end
    end
  end
end
