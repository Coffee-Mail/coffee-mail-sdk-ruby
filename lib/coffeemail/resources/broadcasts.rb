# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Broadcasts para audiências (`/v1/product/broadcasts`).
    #
    # Toda operação exige chave com permissão `full_access`: um 403 vira {CoffeeMail::PermissionError}.
    # Não existe remoção de broadcast; use {#cancel}.
    class Broadcasts < Base
      include Internal::Constants

      # @return [Response] com {Models::BroadcastDetail}
      def create(audience_id:, from_email:, template_id: nil, subject: nil, html: nil, text: nil, reply_to: nil,
                 variables: nil, scheduled_at: nil)
        values = { audience_id:, from_email:, template_id:, subject:, html:, text:, reply_to:, scheduled_at:,
                   variables: }
        broadcast("create", Verbs::POST, Routes::BROADCASTS, object(Models::BroadcastDetail),
                  body: body(values, Internal::Fields::BROADCAST))
      end

      # Uma página de broadcasts (paginação por cursor).
      #
      # @return [Response] com {Models::BroadcastList}
      def list(status: nil, from: nil, to: nil, after: nil, limit: nil)
        broadcast("list", Verbs::GET, Routes::BROADCASTS, object(Models::BroadcastList),
                  query: query({ status:, from:, to:, after:, limit: }, Internal::Fields::LIST_BROADCASTS))
      end

      # Percorre todas as páginas de {#list}; para na primeira falha.
      #
      # @return [Enumerator::Lazy<Response>]
      def pages(**filters)
        Internal::Paginator.cursor { |after| list(**filters, after: after) }
      end

      # @param id [String]
      # @return [Response] com {Models::BroadcastDetail}
      def get(id)
        broadcast("get", Verbs::GET, route(Routes::BROADCAST, id), object(Models::BroadcastDetail))
      end

      # Dispara o broadcast para a audiência.
      #
      # @param id [String]
      # @return [Response] com {Models::SentBroadcast}
      def send(id)
        broadcast("send", Verbs::POST, route(Routes::BROADCAST_SEND, id), object(Models::SentBroadcast))
      end

      # @param id [String]
      # @return [Response] com {Models::TestSendResult}
      def test_send(id, to:, variables: nil)
        broadcast("test_send", Verbs::POST, route(Routes::BROADCAST_TEST_SEND, id), object(Models::TestSendResult),
                  body: body({ to:, variables: }, Internal::Fields::BROADCAST_TEST_SEND))
      end

      # @param id [String]
      # @return [Response] com {Models::CancelledBroadcast}
      def cancel(id)
        broadcast("cancel", Verbs::POST, route(Routes::BROADCAST_CANCEL, id), object(Models::CancelledBroadcast))
      end

      private

      def broadcast(name, http_method, path, decoder, **options)
        request(name, http_method, path, decoder, full_access: true, **options)
      end
    end
  end
end
