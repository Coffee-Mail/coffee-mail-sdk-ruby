# frozen_string_literal: true

module CoffeeMail
  module Internal
    class Options < Data.define(:api_key, :locale, :timeout, :retry_policy, :transport)
      def self.build(api_key:, locale:, timeout:, retry_policy:, transport:, env: ENV)
        validate_locale!(locale)
        key = resolve_key(api_key, env)
        raise missing_key(locale) if key.empty?

        validate!(locale, :INVALID_TIMEOUT, timeout.is_a?(Numeric) && timeout.positive?)
        validate!(locale, :INVALID_RETRY_POLICY, retry_policy.nil? || retry_policy.is_a?(RetryPolicy))
        validate!(locale, :INVALID_TRANSPORT, transport.nil? || transport.respond_to?(:call))
        new(api_key: key, locale: locale, timeout: timeout, retry_policy: retry_policy,
            transport: transport || NetHttpTransport.new)
      end

      def self.resolve_key(api_key, env)
        given = api_key.to_s.strip
        given.empty? ? env.fetch(Constants::Defaults::API_KEY_ENV, "").to_s.strip : given
      end

      def self.missing_key(locale)
        MissingApiKeyError.new(
          message: I18n.message(locale, :MISSING_API_KEY),
          status: Constants::Defaults::NETWORK_STATUS,
          code: ErrorCode::MISSING_API_KEY,
        )
      end

      def self.validate_locale!(locale)
        return if Locale::ALL.include?(locale)

        raise ArgumentError, I18n.message(Locale::DEFAULT, :INVALID_LOCALE, locale: locale.inspect,
                                                                            supported: Locale::ALL.join(", "))
      end

      def self.validate!(locale, key, valid)
        return if valid

        raise ArgumentError, I18n.message(locale, key)
      end

      def masked_key
        "#{api_key[Constants::Defaults::KEY_PREFIX_PATTERN]}#{Constants::Defaults::MASK}"
      end

      def retry_enabled?
        !retry_policy.nil? && retry_policy.enabled?
      end

      def inspect
        "#<CoffeeMail::Internal::Options api_key=#{masked_key} locale=#{locale} timeout=#{timeout}>"
      end

      def to_s = inspect
    end
  end
end
