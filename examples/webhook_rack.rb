# frozen_string_literal: true

require "coffeemail"

module Examples
  class WebhookApp
    OK = [200, { "content-type" => "text/plain" }, ["ok"]].freeze
    REJECTED = [400, { "content-type" => "text/plain" }, ["assinatura inválida"]].freeze

    def initialize(secret:, &handler)
      @secret = secret
      @handler = handler
    end

    def call(env)
      result = CoffeeMail::Webhook.from_rack(env, secret: @secret)
      return REJECTED if result.failure?

      @handler&.call(result.data)
      OK
    end
  end
end
