# frozen_string_literal: true

module CoffeeMail
  # Códigos canônicos de erro, iguais em todos os SDKs oficiais.
  module ErrorCode
    # HTTP 400.
    VALIDATION_ERROR = "VALIDATION_ERROR"
    # HTTP 401.
    UNAUTHORIZED = "UNAUTHORIZED"
    # HTTP 402.
    PAYMENT_REQUIRED = "PAYMENT_REQUIRED"
    # HTTP 403.
    FORBIDDEN = "FORBIDDEN"
    # HTTP 403 em operações de broadcasts.
    PERMISSION_DENIED = "PERMISSION_DENIED"
    # HTTP 404.
    NOT_FOUND = "NOT_FOUND"
    # HTTP 409.
    CONFLICT = "CONFLICT"
    # HTTP 429.
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    # HTTP 500, 502, 503 e 504.
    INTERNAL_SERVER_ERROR = "INTERNAL_SERVER_ERROR"
    # Outro status não 2xx sem código da API.
    API_ERROR = "API_ERROR"
    # Falha de rede ou timeout (status 0).
    NETWORK_ERROR = "NETWORK_ERROR"
    # Resposta 2xx que não pôde ser interpretada.
    INVALID_RESPONSE = "INVALID_RESPONSE"
    # Chave de API ausente na construção do client.
    MISSING_API_KEY = "MISSING_API_KEY"
    # Entrega de webhook com assinatura, timestamp ou payload inválido.
    WEBHOOK_VERIFICATION_FAILED = "WEBHOOK_VERIFICATION_FAILED"
  end
end
