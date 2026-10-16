# frozen_string_literal: true

module CoffeeMail
  module Models
    # Resultado da validação de um endereço. `reason` explica a reprovação e fica `nil` no endereço válido.
    EmailValidationItem = Internal::Model.define(email: :string, format_valid: :boolean, mx_valid: :boolean,
                                                 is_disposable: :boolean, reason: :string)

    # Saldo de créditos de validação do mês após a chamada. `limit` e `remaining` são `nil` quando ilimitado.
    ValidationCredits = Internal::Model.define(limit: :integer, used: :integer, remaining: :integer)

    # Resultado de `validation.validate`.
    EmailValidationResult = Internal::Model.define(items: [EmailValidationItem], valid_count: :integer,
                                                   invalid_count: :integer, credits: ValidationCredits)
  end
end
