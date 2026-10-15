# frozen_string_literal: true

module CoffeeMail
  module Internal
    module Constants
      module Defaults
        BASE_URL = "https://api.coffeemail.com.br"
        API_PREFIX = "/v1/product"
        API_KEY_ENV = "COFFEEMAIL_API_KEY"
        TIMEOUT_SECONDS = 10
        MILLISECONDS_PER_SECOND = 1000
        INTROSPECTION_TTL_SECONDS = 300
        NETWORK_STATUS = 0
        NO_CONTENT_STATUS = 204
        SUCCESS_STATUSES = (200..299)
        MASK = "****"
        KEY_PREFIX_PATTERN = /\A[a-z]+_(?:live|test)_/
        FULL_ACCESS_PERMISSION = "full_access"
        PLAN_QUOTA_EXCEEDED = "PLAN_QUOTA_EXCEEDED"
        FORBIDDEN_STATUS = 403
        RATE_LIMIT_STATUS = 429
        SERVER_ERROR_STATUSES = (500..599)
        RETRY_AFTER_PATTERN = /\A\d{1,9}\z/
      end
    end
  end
end
