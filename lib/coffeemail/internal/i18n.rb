# frozen_string_literal: true

module CoffeeMail
  module Internal
    module I18n
      PT_BR = {
        MISSING_API_KEY: "A chave de API não foi informada. Forneça uma chave válida (ex: cm_live_...) no " \
                         "CoffeeMail::Client.new ou na variável de ambiente COFFEEMAIL_API_KEY.",
        REQUEST_TIMEOUT: "A requisição excedeu o tempo limite configurado de {timeoutMs}ms.",
        NETWORK_ERROR: "Falha de rede ao tentar se comunicar com os servidores do CoffeeMail: {details}",
        UNEXPECTED_ERROR: "Ocorreu um erro inesperado durante a comunicação com a API do CoffeeMail.",
        INVALID_JSON: "A resposta do servidor não pôde ser interpretada como JSON válido.",
        RATE_LIMIT_EXCEEDED: "Limite de requisições excedido (Rate Limit). Tente novamente em alguns segundos.",
        PERMISSION_DENIED: "Esta chave de API não possui a permissão necessária ({requiredPermission}) para " \
                           "executar esta operação. Crie uma chave com permissão 'full_access' no dashboard.",
        INVALID_LOCALE: "Locale inválido: {locale}. Use um de: {supported}.",
        INVALID_TIMEOUT: "O timeout deve ser um número de segundos maior que zero.",
        INVALID_TRANSPORT: "O transport deve responder a call(request).",
        INVALID_RETRY_POLICY: "O retry_policy deve ser um CoffeeMail::RetryPolicy.",
        INVALID_RETRY_SETTING: "RetryPolicy inválida: {setting}.",
        WEBHOOK_MISSING_HEADER: "Entrega de webhook sem os headers de assinatura ou sem segredo configurado.",
        WEBHOOK_INVALID_TIMESTAMP: "Timestamp do webhook inválido ou fora da janela de tolerância.",
        WEBHOOK_INVALID_SIGNATURE: "Assinatura do webhook não confere com o corpo recebido.",
        WEBHOOK_INVALID_PAYLOAD: "O corpo do webhook não é um objeto JSON válido.",
      }.freeze

      EN = {
        MISSING_API_KEY: "API key was not provided. Pass a valid API key (e.g. cm_live_...) to " \
                         "CoffeeMail::Client.new or set the COFFEEMAIL_API_KEY environment variable.",
        REQUEST_TIMEOUT: "The request timed out after {timeoutMs}ms.",
        NETWORK_ERROR: "Network error while attempting to communicate with CoffeeMail API: {details}",
        UNEXPECTED_ERROR: "An unexpected error occurred while communicating with CoffeeMail API.",
        INVALID_JSON: "The server response could not be parsed as valid JSON.",
        RATE_LIMIT_EXCEEDED: "Rate limit exceeded. Please retry in a few moments.",
        PERMISSION_DENIED: "This API key lacks the required permission ({requiredPermission}) for this operation. " \
                           "Create a key with 'full_access' permission in the dashboard.",
        INVALID_LOCALE: "Invalid locale: {locale}. Use one of: {supported}.",
        INVALID_TIMEOUT: "Timeout must be a number of seconds greater than zero.",
        INVALID_TRANSPORT: "Transport must respond to call(request).",
        INVALID_RETRY_POLICY: "retry_policy must be a CoffeeMail::RetryPolicy.",
        INVALID_RETRY_SETTING: "Invalid RetryPolicy: {setting}.",
        WEBHOOK_MISSING_HEADER: "Webhook delivery is missing signature headers or no secret is configured.",
        WEBHOOK_INVALID_TIMESTAMP: "Webhook timestamp is invalid or outside the tolerance window.",
        WEBHOOK_INVALID_SIGNATURE: "Webhook signature does not match the received body.",
        WEBHOOK_INVALID_PAYLOAD: "Webhook body is not a valid JSON object.",
      }.freeze

      CATALOG = { CoffeeMail::Locale::PT_BR => PT_BR, CoffeeMail::Locale::EN => EN }.freeze

      module_function

      def message(locale, key, params = {})
        messages = CATALOG.fetch(locale) { CATALOG.fetch(CoffeeMail::Locale::DEFAULT) }
        template = messages.fetch(key) { key.to_s }
        params.reduce(template) { |text, (name, value)| text.gsub("{#{name}}", value.to_s) }
      end
    end
  end
end
