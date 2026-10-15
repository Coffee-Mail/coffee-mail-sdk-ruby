# frozen_string_literal: true

require "timeout"

module CoffeeMail
  module Internal
    module TransportGuard
      module_function

      def call(transport, request, locale)
        transport.call(request)
      rescue Timeout::Error => e
        timeout_error(e, request, locale)
      rescue StandardError => e
        network_error(e, locale)
      end

      def timeout_error(original, request, locale)
        timeout_ms = (request.timeout * Constants::Defaults::MILLISECONDS_PER_SECOND).round
        NetworkError.new(
          message: I18n.message(locale, :REQUEST_TIMEOUT, timeoutMs: timeout_ms),
          status: Constants::Defaults::NETWORK_STATUS,
          code: ErrorCode::NETWORK_ERROR,
          original: original,
        )
      end

      def network_error(original, locale)
        NetworkError.new(
          message: I18n.message(locale, :NETWORK_ERROR, details: original.message),
          status: Constants::Defaults::NETWORK_STATUS,
          code: ErrorCode::NETWORK_ERROR,
          original: original,
        )
      end
    end
  end
end
