# frozen_string_literal: true

require "openssl"

module CoffeeMail
  # Verificação das entregas de webhook. Não depende do {Client} nem de chave de API.
  #
  # A API assina `"#{timestamp}.#{idempotency_key}.#{corpo_bruto}"` com HMAC-SHA256 usando o segredo
  # `whsec_...` inteiro e envia `sha256=<hex>` em `x-webhook-signature`. Use sempre o corpo **bruto** da
  # requisição, antes de qualquer parser de JSON.
  #
  # O payload não traz o id do e-mail, e `x-webhook-idempotency-key` muda a cada tentativa de entrega:
  # ela não serve para deduplicar retentativas.
  #
  # @example Rack/Rails
  #   result = CoffeeMail::Webhook.from_rack(request, secret: ENV.fetch("COFFEEMAIL_WEBHOOK_SECRET"))
  #   return head(:bad_request) if result.failure?
  #   result.data.event_type
  module Webhook
    # Header com `sha256=<hex>`.
    SIGNATURE_HEADER = "x-webhook-signature"
    # Header com o timestamp Unix (segundos) da assinatura.
    TIMESTAMP_HEADER = "x-webhook-timestamp"
    # Header com a chave da tentativa (16 hex; muda a cada tentativa).
    IDEMPOTENCY_HEADER = "x-webhook-idempotency-key"
    # Header presente (`true`) nos pings de teste.
    TEST_HEADER = "x-webhook-test"
    # Janela padrão de tolerância do timestamp, em segundos.
    DEFAULT_TOLERANCE = 300

    # Tipos de evento enviados pela API.
    module EventType
      Internal::Enum.define(self, %w[email.queued email.processing email.sent email.delivered email.delivery_delayed
                                     email.opened email.clicked email.bounced email.complained email.failed
                                     email.suppressed email.scheduled email.cancelled email.unsubscribed
                                     billing.plan_changed webhook.test])
    end

    # Evento verificado. `data` varia por tipo de evento e mantém as chaves como vieram da API.
    class Event < Data.define(:event_type, :webhook_id, :data, :test)
      # @return [Boolean] `true` em pings de teste
      def test? = test == true
    end

    module_function

    # Confere assinatura e janela de tempo de uma entrega.
    #
    # @param payload [String] corpo bruto da requisição
    # @param headers [Hash, #env] headers da requisição (qualquer caixa, ou env do Rack)
    # @param secret [String] segredo `whsec_...` do webhook
    # @param tolerance [Integer] janela, em segundos
    # @param clock [#call, nil] devolve o instante atual (`Time` ou segundos Unix); padrão `Time.now`
    # @return [Boolean]
    def verify(payload:, headers:, secret:, tolerance: DEFAULT_TOLERANCE, clock: nil)
      Internal::WebhookVerifier.failure_reason(payload, headers, secret, tolerance, clock).nil?
    end

    # Verifica a entrega e devolve o evento desserializado.
    #
    # @param locale [String] idioma da mensagem de erro
    # @return [Response] com {Event}, ou {WebhookVerificationError} com `reason`
    def construct_event(payload:, headers:, secret:, tolerance: DEFAULT_TOLERANCE, clock: nil,
                        locale: Locale::DEFAULT)
      Internal::WebhookVerifier.construct(payload: payload, headers: headers, secret: secret, tolerance: tolerance,
                                          clock: clock, locale: locale)
    end

    # Igual a {construct_event}, lendo corpo e headers de uma requisição Rack (ou do env).
    # O corpo é lido em bytes exatos e rebobinado.
    #
    # @param request [#env, Hash] `Rack::Request`, `ActionDispatch::Request` ou o env
    # @return [Response] com {Event}, ou {WebhookVerificationError}
    def from_rack(request, secret:, tolerance: DEFAULT_TOLERANCE, clock: nil, locale: Locale::DEFAULT)
      env = request.is_a?(Hash) ? request : request.env
      construct_event(payload: Internal::WebhookVerifier.read_body(env), headers: env, secret: secret,
                      tolerance: tolerance, clock: clock, locale: locale)
    end
  end
end
