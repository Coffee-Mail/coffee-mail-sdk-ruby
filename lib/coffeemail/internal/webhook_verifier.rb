# frozen_string_literal: true

require "openssl"

module CoffeeMail
  module Internal
    module WebhookVerifier
      DIGEST = "SHA256"
      SIGNATURE_PREFIX = "sha256="
      SEPARATOR = "."
      NUMERIC = /\A\d+\z/
      RACK_INPUT = "rack.input"
      RACK_PREFIX = "http_"
      TRUE_VALUE = "true"
      LOCAL_STATUS = 0
      REASON_MESSAGES = {
        missing_header: :WEBHOOK_MISSING_HEADER,
        timestamp: :WEBHOOK_INVALID_TIMESTAMP,
        signature: :WEBHOOK_INVALID_SIGNATURE,
        payload: :WEBHOOK_INVALID_PAYLOAD,
      }.freeze

      module_function

      def failure_reason(payload, headers, secret, tolerance, clock)
        signature, timestamp, idempotency_key = header_values(headers)
        return :missing_header unless signature && timestamp && idempotency_key && !secret.to_s.empty?
        return :timestamp unless timestamp_valid?(timestamp, tolerance, clock)
        return :signature unless signature_valid?(signature, timestamp, idempotency_key, payload.to_s, secret)

        nil
      end

      def construct(payload:, headers:, secret:, tolerance:, clock:, locale:)
        reason = failure_reason(payload, headers, secret, tolerance, clock)
        return failure(reason, locale) if reason

        parsed = Wire.parse_object(payload)
        return failure(:payload, locale) if parsed.nil?

        Response.success(event(parsed, headers), LOCAL_STATUS)
      end

      def event(parsed, headers)
        CoffeeMail::Webhook::Event.new(
          event_type: parsed["event_type"],
          webhook_id: parsed["webhook_id"],
          data: parsed.fetch("data", {}),
          test: header(headers, CoffeeMail::Webhook::TEST_HEADER) == TRUE_VALUE,
        )
      end

      def failure(reason, locale)
        Response.failure(WebhookVerificationError.new(
                           message: I18n.message(locale, REASON_MESSAGES.fetch(reason)),
                           status: LOCAL_STATUS,
                           code: ErrorCode::WEBHOOK_VERIFICATION_FAILED,
                           reason: reason,
                         ))
      end

      def header_values(headers)
        [CoffeeMail::Webhook::SIGNATURE_HEADER, CoffeeMail::Webhook::TIMESTAMP_HEADER,
         CoffeeMail::Webhook::IDEMPOTENCY_HEADER].map { |name| header(headers, name) }
      end

      def header(headers, name)
        source = headers.is_a?(Hash) ? headers : headers.env
        found = source.find { |key, value| normalize(key) == name && !value.to_s.empty? }
        found&.last&.to_s
      end

      def normalize(key)
        key.to_s.downcase.delete_prefix(RACK_PREFIX).tr("_", "-")
      end

      def timestamp_valid?(timestamp, tolerance, clock)
        return false unless timestamp.match?(NUMERIC)

        now = (clock || -> { Time.now }).call.to_i
        (now - timestamp.to_i).abs <= tolerance
      end

      def signature_valid?(signature, timestamp, idempotency_key, payload, secret)
        signed = [timestamp, idempotency_key, ""].join(SEPARATOR).b + payload.b
        expected = "#{SIGNATURE_PREFIX}#{OpenSSL::HMAC.hexdigest(DIGEST, secret, signed)}"
        signature.bytesize == expected.bytesize && OpenSSL.fixed_length_secure_compare(signature, expected)
      end

      def read_body(env)
        input = env[RACK_INPUT]
        return "" if input.nil?

        body = input.read.to_s
        input.rewind if input.respond_to?(:rewind)
        body
      end
    end
  end
end
