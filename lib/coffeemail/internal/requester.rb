# frozen_string_literal: true

require "securerandom"
require "uri"

module CoffeeMail
  module Internal
    class Requester
      RETRYABLE_METHODS = %w[GET DELETE].freeze
      POST = "POST"
      FIRST_ATTEMPT = 1

      attr_reader :options

      def initialize(options, sleeper: Kernel.method(:sleep), random: Random.new)
        @options = options
        @sleeper = sleeper
        @random = random
        freeze
      end

      def call(operation)
        perform(build_request(operation), operation, FIRST_ATTEMPT)
      end

      private

      def perform(request, operation, attempt)
        response = attempt(request, operation)
        policy = options.retry_policy
        error = response.error
        return response unless policy && error && retry?(policy, request, error, attempt)

        retry_after = error.is_a?(RateLimitError) ? error.retry_after_seconds : nil
        @sleeper.call(Backoff.delay(policy, attempt, retry_after, @random))
        perform(request, operation, attempt + 1)
      end

      def attempt(request, operation)
        result = TransportGuard.call(options.transport, request, options.locale)
        return Response.failure(result) if result.is_a?(Error)

        interpret(result, operation)
      end

      def interpret(http, operation)
        return Response.failure(ErrorMapper.build(http, operation, options.locale)) unless success?(http)
        return Response.success(operation.empty, http.status) if empty_body?(http)

        decode(http, operation)
      end

      def decode(http, operation)
        data = Wire.decode(http.body, operation.decoder)
        return Response.failure(ErrorMapper.invalid_response(http, options.locale)) if data.equal?(Wire::INVALID)

        Response.success(data, http.status)
      end

      def success?(http)
        Constants::Defaults::SUCCESS_STATUSES.cover?(http.status)
      end

      def empty_body?(http)
        http.status == Constants::Defaults::NO_CONTENT_STATUS || http.body.to_s.strip.empty?
      end

      def retry?(policy, request, error, attempt)
        return false unless policy.enabled? && attempt < policy.max_attempts
        return false unless retryable_request?(request)

        retryable_error?(error)
      end

      def retryable_request?(request)
        RETRYABLE_METHODS.include?(request.http_method) || request.headers.key?(Constants::Headers::IDEMPOTENCY_KEY)
      end

      def retryable_error?(error)
        return true if error.is_a?(NetworkError)
        return !credits_exhausted?(error) if error.is_a?(RateLimitError)

        Constants::Defaults::SERVER_ERROR_STATUSES.cover?(error.status)
      end

      def credits_exhausted?(error)
        Constants::Defaults::NON_RETRYABLE_RATE_LIMIT_CODES.include?(error.api_code.to_s)
      end

      def build_request(operation)
        body = operation.body.nil? ? nil : Wire.dump(operation.body)
        HttpRequest.new(
          http_method: operation.http_method,
          url: url(operation),
          headers: headers(operation, body),
          body: body,
          timeout: options.timeout,
        )
      end

      def url(operation)
        base = "#{Constants::Defaults::BASE_URL}#{Constants::Defaults::API_PREFIX}#{operation.path}"
        operation.query.empty? ? base : "#{base}?#{URI.encode_www_form(operation.query)}"
      end

      def headers(operation, body)
        defaults = {
          Constants::Headers::AUTHORIZATION => "#{Constants::Headers::BEARER_PREFIX}#{options.api_key}",
          Constants::Headers::ACCEPT => Constants::Headers::JSON_MEDIA_TYPE,
          Constants::Headers::ACCEPT_LANGUAGE => options.locale,
          Constants::Headers::USER_AGENT => Constants::Headers::USER_AGENT_VALUE,
        }
        content = body.nil? ? {} : { Constants::Headers::CONTENT_TYPE => Constants::Headers::JSON_MEDIA_TYPE }
        defaults.merge(content, request_id, operation.headers, generated_idempotency(operation)).freeze
      end

      def request_id
        current = CoffeeMail.current_request_id
        current.nil? || current.empty? ? {} : { Constants::Headers::REQUEST_ID => current }
      end

      def generated_idempotency(operation)
        return {} unless operation.http_method == POST && operation.idempotent_post && options.retry_enabled?
        return {} if operation.headers.key?(Constants::Headers::IDEMPOTENCY_KEY)

        { Constants::Headers::IDEMPOTENCY_KEY => SecureRandom.uuid }
      end
    end
  end
end
