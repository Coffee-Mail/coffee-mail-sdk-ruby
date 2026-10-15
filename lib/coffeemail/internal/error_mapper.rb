# frozen_string_literal: true

module CoffeeMail
  module Internal
    module ErrorMapper
      ERROR_CLASSES = {
        400 => ValidationError,
        401 => AuthenticationError,
        402 => PaymentRequiredError,
        403 => ForbiddenError,
        404 => NotFoundError,
        409 => ConflictError,
        429 => RateLimitError,
        500 => InternalServerError,
        502 => InternalServerError,
        503 => InternalServerError,
        504 => InternalServerError,
      }.freeze
      CANONICAL_CODES = {
        400 => ErrorCode::VALIDATION_ERROR,
        401 => ErrorCode::UNAUTHORIZED,
        402 => ErrorCode::PAYMENT_REQUIRED,
        403 => ErrorCode::FORBIDDEN,
        404 => ErrorCode::NOT_FOUND,
        409 => ErrorCode::CONFLICT,
        429 => ErrorCode::RATE_LIMIT_EXCEEDED,
        500 => ErrorCode::INTERNAL_SERVER_ERROR,
        502 => ErrorCode::INTERNAL_SERVER_ERROR,
        503 => ErrorCode::INTERNAL_SERVER_ERROR,
        504 => ErrorCode::INTERNAL_SERVER_ERROR,
      }.freeze
      FALLBACK_MESSAGES = { 429 => :RATE_LIMIT_EXCEEDED }.freeze
      OPERATION_DETAIL = "operation"
      PERMISSION_DETAIL = "requiredPermission"

      Attributes = Data.define(:message, :status, :code, :api_code, :details, :request_id)

      module_function

      def build(response, operation, locale)
        attributes = attributes(response, locale)
        return permission_error(attributes, operation, locale) if permission_remap?(response, operation)
        return rate_limit_error(attributes, response) if response.status == Constants::Defaults::RATE_LIMIT_STATUS

        klass = ERROR_CLASSES.fetch(response.status, Error)
        klass.new(message: attributes.message, status: attributes.status, code: attributes.code,
                  api_code: attributes.api_code, details: attributes.details, request_id: attributes.request_id)
      end

      def invalid_response(response, locale)
        InvalidResponseError.new(
          message: I18n.message(locale, :INVALID_JSON),
          status: response.status,
          code: ErrorCode::INVALID_RESPONSE,
          request_id: response.header(Constants::Headers::REQUEST_ID),
        )
      end

      def attributes(response, locale)
        envelope = Wire.parse_object(response.body)
        body = error_body(envelope)
        api_code = body["code"]&.to_s
        Attributes.new(
          message: message(response, envelope, body, locale),
          status: response.status,
          code: CANONICAL_CODES.fetch(response.status) { api_code || ErrorCode::API_ERROR },
          api_code: api_code,
          details: details(body),
          request_id: response.header(Constants::Headers::REQUEST_ID),
        )
      end

      def error_body(envelope)
        error = envelope&.fetch("error", nil)
        error.is_a?(Hash) ? error : {}
      end

      def message(response, envelope, body, locale)
        raw = envelope.nil? ? response.body : nil
        candidates = [body["message"], envelope&.fetch("message", nil), raw]
        found = candidates.find { |candidate| candidate.is_a?(String) && !candidate.strip.empty? }
        found || I18n.message(locale, FALLBACK_MESSAGES.fetch(response.status, :UNEXPECTED_ERROR))
      end

      def details(body)
        [body["meta"], body["details"]].grep(Hash).reduce({}, :merge)
      end

      def retry_after(response)
        value = response.header(Constants::Headers::RETRY_AFTER).to_s.strip
        value.match?(Constants::Defaults::RETRY_AFTER_PATTERN) ? value.to_i : nil
      end

      def rate_limit_error(attributes, response)
        RateLimitError.new(message: attributes.message, status: attributes.status, code: attributes.code,
                           api_code: attributes.api_code, details: attributes.details,
                           request_id: attributes.request_id, retry_after_seconds: retry_after(response))
      end

      def permission_remap?(response, operation)
        operation.full_access && response.status == Constants::Defaults::FORBIDDEN_STATUS
      end

      def permission_error(attributes, operation, locale)
        permission = Constants::Defaults::FULL_ACCESS_PERMISSION
        PermissionError.new(
          message: I18n.message(locale, :PERMISSION_DENIED,
                                requiredPermission: "#{permission} (called by #{operation.name})"),
          status: attributes.status,
          code: ErrorCode::PERMISSION_DENIED,
          api_code: attributes.api_code,
          details: attributes.details.merge(OPERATION_DETAIL => operation.name, PERMISSION_DETAIL => permission),
          request_id: attributes.request_id,
          required_permission: permission,
        )
      end
    end
  end
end
