# frozen_string_literal: true

module CoffeeMail
  # Erro base de toda falha do SDK. É devolvido em `Response#error` e só é levantado por `Response#unwrap!`.
  class Error < StandardError
    # @return [Integer] status HTTP (0 para falha de rede)
    attr_reader :status
    # @return [String] código canônico (ver {ErrorCode})
    attr_reader :code
    # @return [String, nil] código original enviado pela API (ex.: `PLAN_QUOTA_EXCEEDED`)
    attr_reader :api_code
    # @return [Hash{String => Object}] metadados do erro (`error.meta` + `error.details`)
    attr_reader :details
    # @return [String, nil] valor do header `x-request-id` da resposta
    attr_reader :request_id

    # @param message [String]
    # @param status [Integer]
    # @param code [String]
    # @param api_code [String, nil]
    # @param details [Hash]
    # @param request_id [String, nil]
    def initialize(message:, status:, code:, api_code: nil, details: {}, request_id: nil)
      super(message)
      @status = status
      @code = code
      @api_code = api_code
      @details = details.dup.freeze
      @request_id = request_id
    end

    # @return [String]
    def inspect
      "#<#{self.class.name} status=#{status} code=#{code} api_code=#{api_code.inspect} " \
        "request_id=#{request_id.inspect} message=#{message.inspect}>"
    end
  end

  # HTTP 400: payload rejeitado pela validação da API.
  class ValidationError < Error; end

  # HTTP 401: chave de API ausente, inválida ou revogada.
  class AuthenticationError < Error; end

  # HTTP 402: o plano da organização não cobre a operação.
  class PaymentRequiredError < Error; end

  # HTTP 403: a chave não tem acesso ao recurso.
  class ForbiddenError < Error; end

  # HTTP 403 em broadcasts: a chave precisa da permissão `full_access`.
  class PermissionError < ForbiddenError
    # @return [String] permissão exigida pela operação
    attr_reader :required_permission

    # @param required_permission [String]
    def initialize(required_permission:, message:, status:, code:, api_code: nil, details: {}, request_id: nil)
      super(message: message, status: status, code: code, api_code: api_code, details: details, request_id: request_id)
      @required_permission = required_permission
    end
  end

  # HTTP 404: recurso inexistente.
  class NotFoundError < Error; end

  # HTTP 409: conflito com o estado atual do recurso.
  class ConflictError < Error; end

  # HTTP 429: limite de requisições, cota do plano (`api_code == "PLAN_QUOTA_EXCEEDED"`) ou créditos de
  # validação do mês esgotados (`api_code == "VALIDATION_CREDITS_EXHAUSTED"`).
  class RateLimitError < Error
    # @return [Integer, nil] segundos indicados em `Retry-After`
    attr_reader :retry_after_seconds

    # @param retry_after_seconds [Integer, nil]
    def initialize(message:, status:, code:, api_code: nil, details: {}, request_id: nil, retry_after_seconds: nil)
      super(message: message, status: status, code: code, api_code: api_code, details: details, request_id: request_id)
      @retry_after_seconds = retry_after_seconds
    end
  end

  # HTTP 5xx: falha do lado da API.
  class InternalServerError < Error; end

  # Falha de rede ou timeout. A exceção original fica em `cause`.
  class NetworkError < Error
    # @param original [Exception, nil]
    def initialize(message:, status:, code:, api_code: nil, details: {}, request_id: nil, original: nil)
      super(message: message, status: status, code: code, api_code: api_code, details: details, request_id: request_id)
      @original = original
    end

    # @return [Exception, nil]
    def cause = @original || super
  end

  # Resposta 2xx com corpo que não pôde ser interpretado.
  class InvalidResponseError < Error; end

  # Levantado por `Client.new` quando nenhuma chave de API foi informada.
  class MissingApiKeyError < Error; end

  # Entrega de webhook que não passou na verificação.
  class WebhookVerificationError < Error
    # @return [Symbol] `:signature`, `:timestamp`, `:missing_header` ou `:payload`
    attr_reader :reason

    # @param reason [Symbol]
    def initialize(reason:, message:, status:, code:, api_code: nil, details: {}, request_id: nil)
      super(message: message, status: status, code: code, api_code: api_code, details: details, request_id: request_id)
      @reason = reason
    end
  end
end
