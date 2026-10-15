# frozen_string_literal: true

module CoffeeMail
  module Internal
    module Constants
      module Headers
        AUTHORIZATION = "authorization"
        ACCEPT = "accept"
        CONTENT_TYPE = "content-type"
        ACCEPT_LANGUAGE = "accept-language"
        USER_AGENT = "user-agent"
        IDEMPOTENCY_KEY = "x-idempotency-key"
        SANDBOX = "x-coffeemail-sandbox"
        REQUEST_ID = "x-request-id"
        RETRY_AFTER = "retry-after"
        JSON_MEDIA_TYPE = "application/json"
        BEARER_PREFIX = "Bearer "
        SANDBOX_ENABLED = "true"
        USER_AGENT_VALUE = "coffeemail-ruby/#{CoffeeMail::VERSION}".freeze
      end
    end
  end
end
