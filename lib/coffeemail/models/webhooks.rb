# frozen_string_literal: true

module CoffeeMail
  module Models
    # Detalhe de um webhook. `secret` só vem completo em `webhooks.create`; `inspect` o mascara.
    WebhookDetail = Internal::Model.define(
      id: :string, url: :string, events: :strings, status: :string, description: :string, has_secret: :boolean,
      secret: :string, secret_preview: :string, created_at: :time,
      masked: %i[secret]
    )

    # Resultado de `webhooks.list`.
    WebhookList = Internal::Model.define(webhooks: [WebhookDetail])

    # Resultado de `webhooks.toggle`.
    ToggledWebhook = Internal::Model.define(id: :string, status: :string)

    # Resultado de `webhooks.rotate_secret`; `inspect` mascara o segredo.
    RotatedSecret = Internal::Model.define(webhook_id: :string, secret: :string, masked: %i[secret])

    # Entrega de um evento para o webhook.
    WebhookDelivery = Internal::Model.define(
      id: :string, webhook_id: :string, email_event_id: :string, event_type: :string, response_status: :integer,
      response_body: :string, attempts: :integer, last_error: :string, status: :string, next_run_at: :time,
      created_at: :time
    )

    # Entrega com o corpo enviado ao endpoint (`webhooks.get_delivery` e `webhooks.replay_delivery`).
    WebhookDeliveryDetail = Internal::Model.define(
      id: :string, webhook_id: :string, email_event_id: :string, event_type: :string, response_status: :integer,
      response_body: :string, attempts: :integer, last_error: :string, status: :string, next_run_at: :time,
      created_at: :time, request_payload: :string
    )

    # Resultado de `webhooks.list_deliveries`.
    WebhookDeliveryList = Internal::Model.define(deliveries: [WebhookDelivery])

    # Resultado de `webhooks.test`.
    WebhookTestResult = Internal::Model.define(status: :string, status_code: :integer, body: :string, error: :string)
  end
end
