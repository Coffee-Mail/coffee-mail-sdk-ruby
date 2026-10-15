# frozen_string_literal: true

module CoffeeMail
  # Modelos de resposta da API: imutáveis (`Data`), com datas em `Time` e campos ausentes em `nil`.
  module Models
    # Resultado de `emails.send` e `emails.resend` (HTTP 202).
    SendEmailResult = Internal::Model.define(id: :string, status: :string, queued_at: :time)

    # Item de `emails.send_batch`: `ok` com `data`, ou `ok == false` com `error`.
    BatchSendItem = Internal::Model.define(ok: :boolean, data: SendEmailResult, error: :string)

    # Tag de um e-mail.
    Tag = Internal::Model.define(name: :string, value: :string)

    # Chave de API que enviou o e-mail.
    ApiKeyReference = Internal::Model.define(id: :string, name: :string)

    # Detalhe de um e-mail.
    EmailDetail = Internal::Model.define(
      id: :string, from: :string, to: :strings, cc: :strings, bcc: :strings, subject: :string, status: :string,
      attempts: :integer, last_error: :string, message_id: :string, api_key: ApiKeyReference, created_at: :time,
      scheduled_at: :time, sent_at: :time, delivered_at: :time, bounced_at: :time, failed_at: :time,
      complained_at: :time, suppressed_at: :time, opened_at: :time, first_clicked_at: :time, open_count: :integer,
      click_count: :integer, proxy_open_count: :integer, tags: [Tag], html: :string, text: :string
    )

    # Página de `emails.list` (paginação por cursor).
    EmailList = Internal::Model.define(emails: [EmailDetail], next_cursor: :string)

    # Evento da linha do tempo de um e-mail.
    EmailEvent = Internal::Model.define(type: :string, timestamp: :time, metadata: :hash)

    # Resultado de `emails.get_events`.
    EmailEvents = Internal::Model.define(id: :string, events: [EmailEvent])

    # Tag com os valores já usados.
    TagValues = Internal::Model.define(name: :string, values: :strings)

    # Resultado de `emails.get_tags`.
    EmailTags = Internal::Model.define(tags: [TagValues])
  end
end
