# frozen_string_literal: true

require "time"

module CoffeeMail
  module Internal
    module Encoder
      TIME_PRECISION = 3
      ADDRESS = { email: "email", name: "name" }.freeze

      module_function

      def body(values, table)
        values.each_with_object({}) do |(key, value), out|
          next if value.nil?

          spec = table.fetch(key.to_sym) { key.to_s }
          name, kind = spec.is_a?(Array) ? spec : [spec, nil]
          out[name.to_s] = convert(value, kind)
        end
      end

      def query(values, table)
        body(values, table).transform_values { |value| scalar(value) }
      end

      def convert(value, kind)
        return list(value, kind) if kind.is_a?(Hash)
        return address(value) if kind == :address
        return Array(value).map { |entry| address(entry) } if kind == :addresses

        plain(value)
      end

      def list(value, table)
        value.map { |item| item.is_a?(Hash) ? body(item, table) : plain(item) }
      end

      def address(value)
        return { "email" => value } if value.is_a?(String)

        body(value, ADDRESS)
      end

      def plain(value)
        return value.utc.iso8601(TIME_PRECISION) if value.is_a?(Time)
        return value.to_s if value.is_a?(Symbol)
        return value.to_h { |key, entry| [key.to_s, plain(entry)] } if value.is_a?(Hash)
        return value.map { |entry| plain(entry) } if value.is_a?(Array)

        value
      end

      def scalar(value)
        value.is_a?(Array) ? value.join(",") : value.to_s
      end
    end
  end
end
