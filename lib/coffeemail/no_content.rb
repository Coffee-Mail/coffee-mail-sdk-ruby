# frozen_string_literal: true

module CoffeeMail
  # Marcador de sucesso sem corpo (HTTP 204 ou 2xx vazio).
  class NoContent
    # @return [String]
    def inspect = "CoffeeMail::NO_CONTENT"

    # @return [String]
    def to_s = inspect
  end

  # Valor de `Response#data` quando a API responde sem corpo.
  NO_CONTENT = NoContent.new.freeze
end
