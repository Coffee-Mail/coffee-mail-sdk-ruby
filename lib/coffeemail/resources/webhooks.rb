# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Endpoints de webhook (`/v1/product/webhooks`). Para verificar entregas, use {CoffeeMail::Webhook}.
    class Webhooks < Base
      include Internal::Constants

      # O `secret` vem na resposta uma única vez; guarde-o.
      #
      # @return [Response] com {Models::WebhookDetail}
      def create(url:, events:, description: nil)
        request("create", Verbs::POST, Routes::WEBHOOKS, object(Models::WebhookDetail),
                body: body({ url:, events:, description: }, Internal::Fields::WEBHOOK))
      end

      # @return [Response] com {Models::WebhookList}
      def list(status: nil)
        request("list", Verbs::GET, Routes::WEBHOOKS, object(Models::WebhookList),
                query: query({ status: }, Internal::Fields::LIST_WEBHOOKS))
      end

      # @param id [String]
      # @return [Response] com {Models::WebhookDetail}
      def get(id)
        request("get", Verbs::GET, route(Routes::WEBHOOK, id), object(Models::WebhookDetail))
      end

      # Atualização parcial.
      #
      # @param id [String]
      # @return [Response] com {Models::WebhookDetail}
      def update(id, url: nil, events: nil, description: nil)
        request("update", Verbs::PUT, route(Routes::WEBHOOK, id), object(Models::WebhookDetail),
                body: body({ url:, events:, description: }, Internal::Fields::WEBHOOK))
      end

      # Ativa ou pausa o webhook.
      #
      # @param id [String]
      # @param status [String] `CoffeeMail::WebhookStatus::ACTIVE` ou `PAUSED`
      # @return [Response] com {Models::ToggledWebhook}
      def toggle(id, status:)
        request("toggle", Verbs::PATCH, route(Routes::WEBHOOK, id), object(Models::ToggledWebhook),
                body: body({ status: }, Internal::Fields::WEBHOOK_TOGGLE))
      end

      # @param id [String]
      # @return [Response] com {CoffeeMail::NO_CONTENT}
      def delete(id)
        request("delete", Verbs::DELETE, route(Routes::WEBHOOK, id), raw)
      end

      # Gera um novo segredo; o anterior deixa de valer.
      #
      # @param id [String]
      # @return [Response] com {Models::RotatedSecret}
      def rotate_secret(id)
        request("rotate_secret", Verbs::POST, route(Routes::WEBHOOK_ROTATE_SECRET, id), object(Models::RotatedSecret))
      end

      # @param id [String]
      # @return [Response] com {Models::WebhookDeliveryList}
      def list_deliveries(id, event_type: nil, status: nil, from: nil, to: nil, limit: nil)
        filters = { event_type:, status:, from:, to:, limit: }
        request("list_deliveries", Verbs::GET, route(Routes::WEBHOOK_DELIVERIES, id),
                object(Models::WebhookDeliveryList), query: query(filters, Internal::Fields::LIST_DELIVERIES))
      end

      # Envia um ping de teste (`webhook.test`) para o endpoint.
      #
      # @param id [String]
      # @return [Response] com {Models::WebhookTestResult}
      def test(id)
        request("test", Verbs::POST, route(Routes::WEBHOOK_TEST, id), object(Models::WebhookTestResult))
      end

      # Busca uma entrega com o corpo enviado ao endpoint (`request_payload`).
      #
      # @param id [String]
      # @param delivery_id [String]
      # @return [Response] com {Models::WebhookDeliveryDetail}; webhook ou entrega inexistente vira {NotFoundError}
      def get_delivery(id, delivery_id)
        request("get_delivery", Verbs::GET, route(Routes::WEBHOOK_DELIVERY, id, delivery_id),
                object(Models::WebhookDeliveryDetail))
      end

      # Reenvia o mesmo corpo de uma entrega anterior como uma entrega nova.
      #
      # @param id [String]
      # @param delivery_id [String]
      # @return [Response] com a nova {Models::WebhookDeliveryDetail}; entrega ainda pendente ou webhook
      #   inativo viram {ConflictError}, e webhook ou entrega inexistente vira {NotFoundError}
      def replay_delivery(id, delivery_id)
        request("replay_delivery", Verbs::POST, route(Routes::WEBHOOK_DELIVERY_REPLAY, id, delivery_id),
                object(Models::WebhookDeliveryDetail))
      end
    end
  end
end
