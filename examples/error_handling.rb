# frozen_string_literal: true

require "coffeemail"

module Examples
  module ErrorHandling
    MESSAGES = {
      CoffeeMail::ValidationError => ->(error) { "Payload inválido: #{error.details.fetch("issues", [])}" },
      CoffeeMail::AuthenticationError => ->(_error) { "Confira a COFFEEMAIL_API_KEY" },
      CoffeeMail::RateLimitError => ->(error) { "Aguarde #{error.retry_after_seconds || 60}s (#{error.api_code})" },
      CoffeeMail::NetworkError => ->(error) { "Sem conexão: #{error.message}" },
    }.freeze

    module_function

    def run(client)
      response = client.emails.get("00000000-0000-0000-0000-000000000000")
      return "Encontrado: #{response.data.id}" if response.success?

      error = response.error
      handler = MESSAGES.find { |klass, _| error.is_a?(klass) }&.last
      handler ? handler.call(error) : "#{error.code} (request_id=#{error.request_id}): #{error.message}"
    end
  end
end

puts Examples::ErrorHandling.run(CoffeeMail::Client.new) if $PROGRAM_NAME == __FILE__
