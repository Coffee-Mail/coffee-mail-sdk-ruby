# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Envio e consulta de e-mails transacionais (`/v1/product/emails`).
    #
    # Sem `idempotency_key`, a API deduplica envios idênticos pelo hash do payload: dois `send` iguais
    # devolvem o mesmo id.
    class Emails < Base
      include Internal::Constants

      # Enfileira um e-mail.
      #
      # Endereços aceitam String (`"ana@exemplo.com"`) ou Hash (`{ email:, name: }`). `idempotency_key` vira o
      # header `x-idempotency-key` e `sandbox: true` vira `x-coffeemail-sandbox`; nenhum dos dois vai no corpo.
      #
      # @example
      #   client.emails.send(from: "app@exemplo.com", to: "ana@exemplo.com", subject: "Oi", html: "<p>Oi</p>")
      # @return [Response] com {Models::SendEmailResult}
      def send(from:, to:, subject: nil, html: nil, text: nil, cc: nil, bcc: nil, reply_to: nil, headers: nil,
               attachments: nil, template_id: nil, variables: nil, email_type: nil, suppression_category: nil,
               tags: nil, scheduled_at: nil, metadata: nil, idempotency_key: nil, sandbox: false)
        payload = { from:, to:, subject:, html:, text:, cc:, bcc:, reply_to:, headers:, attachments:, template_id:,
                    variables:, email_type:, suppression_category:, tags:, scheduled_at:, metadata: }
        request("send", Verbs::POST, Routes::EMAILS, object(Models::SendEmailResult),
                body: body(payload, Internal::Fields::SEND_EMAIL),
                headers: send_headers(idempotency_key, sandbox), idempotent_post: true)
      end

      # Enfileira de 1 a 100 e-mails. Cada item é um Hash com as chaves de {#send}; `idempotency_key` e
      # `sandbox` dos itens viram headers únicos da requisição.
      #
      # @param items [Array<Hash>]
      # @return [Response] com Array de {Models::BatchSendItem}
      def send_batch(items)
        headers = items.reduce({}) { |merged, item| merged.merge(send_headers(item[:idempotency_key], item[:sandbox])) }
        payload = items.map { |item| body(item.except(:idempotency_key, :sandbox), Internal::Fields::SEND_EMAIL) }
        request("send_batch", Verbs::POST, Routes::EMAILS_BATCH, list_of(Models::BatchSendItem),
                body: payload, headers: headers, idempotent_post: true)
      end

      # @param id [String]
      # @return [Response] com {Models::EmailDetail}
      def get(id)
        request("get", Verbs::GET, route(Routes::EMAIL, id), object(Models::EmailDetail))
      end

      # Uma página de e-mails (paginação por cursor). Use {#pages} para percorrer todas.
      #
      # @return [Response] com {Models::EmailList}
      def list(status: nil, recipient: nil, from_email: nil, subject_contains: nil, api_key_id: nil, tag: nil,
               from: nil, to: nil, after: nil, limit: nil)
        filters = { status:, recipient:, from_email:, subject_contains:, api_key_id:, tag:, from:, to:, after:, limit: }
        request("list", Verbs::GET, Routes::EMAILS, object(Models::EmailList),
                query: query(filters, Internal::Fields::LIST_EMAILS))
      end

      # Percorre todas as páginas de {#list}, uma `Response` por página; para na primeira falha.
      #
      # @return [Enumerator::Lazy<Response>]
      def pages(**filters)
        Internal::Paginator.cursor { |after| list(**filters, after: after) }
      end

      # @param id [String]
      # @return [Response] com {Models::EmailEvents}
      def get_events(id)
        request("get_events", Verbs::GET, route(Routes::EMAIL_EVENTS, id), object(Models::EmailEvents))
      end

      # @return [Response] com {Models::EmailTags}
      def get_tags
        request("get_tags", Verbs::GET, Routes::EMAILS_TAGS, object(Models::EmailTags))
      end

      # Cancela um e-mail agendado.
      #
      # @param id [String]
      # @return [Response] com {CoffeeMail::NO_CONTENT}
      def cancel(id)
        request("cancel", Verbs::POST, route(Routes::EMAIL_CANCEL, id), raw)
      end

      # @param id [String]
      # @return [Response] com {Models::SendEmailResult}
      def resend(id)
        request("resend", Verbs::POST, route(Routes::EMAIL_RESEND, id), object(Models::SendEmailResult))
      end

      private

      def send_headers(idempotency_key, sandbox)
        idempotency = idempotency_key.nil? ? {} : { Headers::IDEMPOTENCY_KEY => idempotency_key.to_s }
        sandbox ? idempotency.merge(Headers::SANDBOX => Headers::SANDBOX_ENABLED) : idempotency
      end
    end
  end
end
