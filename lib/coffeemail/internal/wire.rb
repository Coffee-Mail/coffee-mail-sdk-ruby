# frozen_string_literal: true

require "json"

module CoffeeMail
  module Internal
    module Wire
      INVALID = Object.new.freeze
      DECODE_FAILURES = [JSON::ParserError, TypeError, NoMethodError, KeyError, ArgumentError].freeze

      module_function

      def dump(value)
        JSON.generate(value)
      end

      def decode(body, decoder)
        decoder.call(JSON.parse(body))
      rescue *DECODE_FAILURES
        INVALID
      end

      def parse_object(body)
        parsed = JSON.parse(body.to_s)
        parsed.is_a?(Hash) ? parsed : nil
      rescue JSON::ParserError
        nil
      end
    end
  end
end
