# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Validação de endereços de e-mail (`/v1/product/validate`).
    class Validation < Base
      include Internal::Constants

      # Valida formato, MX e domínio descartável de 1 a 100 endereços. Cada endereço consome um crédito
      # de validação do mês.
      #
      # @param emails [Array<String>]
      # @return [Response] com {Models::EmailValidationResult}; créditos do mês esgotados viram
      #   {RateLimitError} com `api_code == "VALIDATION_CREDITS_EXHAUSTED"`, sem nova tentativa automática
      def validate(emails)
        request("validate", Verbs::POST, Routes::VALIDATE, object(Models::EmailValidationResult),
                body: body({ emails: }, Internal::Fields::VALIDATE))
      end
    end
  end
end
