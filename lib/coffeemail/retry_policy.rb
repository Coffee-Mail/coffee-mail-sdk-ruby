# frozen_string_literal: true

module CoffeeMail
  # Política de novas tentativas automáticas. Desligada por padrão; ativa com `max_attempts > 1`.
  #
  # Só são repetidos erros de rede, respostas 5xx e 429 que não sejam cota do plano esgotada
  # (`PLAN_QUOTA_EXCEEDED`). GET e DELETE são sempre elegíveis; POST só no envio de e-mail, que aceita
  # chave de idempotência. Sem chave informada, o SDK gera um UUID antes da primeira tentativa e o
  # reutiliza em todas.
  #
  # @example
  #   CoffeeMail::Client.new(retry_policy: CoffeeMail::RetryPolicy.new(max_attempts: 3))
  class RetryPolicy
    # Espera base padrão do backoff exponencial, em segundos.
    DEFAULT_BASE_DELAY = 0.5
    # Teto padrão de espera entre tentativas, em segundos (vale também para `Retry-After`).
    DEFAULT_MAX_DELAY = 30
    # Uma única tentativa: sem retry.
    SINGLE_ATTEMPT = 1

    # @return [Integer] total de tentativas, incluindo a primeira
    attr_reader :max_attempts
    # @return [Numeric] espera base, em segundos
    attr_reader :base_delay
    # @return [Numeric] teto de espera, em segundos
    attr_reader :max_delay

    # @param max_attempts [Integer]
    # @param base_delay [Numeric]
    # @param max_delay [Numeric]
    # @raise [ArgumentError] quando algum valor não é positivo
    def initialize(max_attempts:, base_delay: DEFAULT_BASE_DELAY, max_delay: DEFAULT_MAX_DELAY)
      validate!("max_attempts", max_attempts.is_a?(Integer) && max_attempts >= SINGLE_ATTEMPT)
      validate!("base_delay", base_delay.is_a?(Numeric) && base_delay.positive?)
      validate!("max_delay", max_delay.is_a?(Numeric) && max_delay >= base_delay)
      @max_attempts = max_attempts
      @base_delay = base_delay
      @max_delay = max_delay
      freeze
    end

    # @return [Boolean]
    def enabled? = max_attempts > SINGLE_ATTEMPT

    # @return [String]
    def inspect
      "#<CoffeeMail::RetryPolicy max_attempts=#{max_attempts} base_delay=#{base_delay} " \
        "max_delay=#{max_delay}>"
    end

    private

    def validate!(setting, valid)
      return if valid

      raise ArgumentError, Internal::I18n.message(Locale::DEFAULT, :INVALID_RETRY_SETTING, setting: setting)
    end
  end
end
