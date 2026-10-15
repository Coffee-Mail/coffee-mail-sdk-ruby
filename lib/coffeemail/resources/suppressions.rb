# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Lista de supressão (`/v1/product/suppressions`). As rotas usam o **id** da supressão, nunca o e-mail.
    class Suppressions < Base
      include Internal::Constants

      # @return [Response] com {Models::SuppressionDetail}
      def create(email:, reason: nil, expires_at: nil)
        request("create", Verbs::POST, Routes::SUPPRESSIONS, object(Models::SuppressionDetail),
                body: body({ email:, reason:, expires_at: }, Internal::Fields::SUPPRESSION))
      end

      # Uma página de supressões (paginação por cursor).
      #
      # @return [Response] com {Models::SuppressionList}
      def list(status: nil, reason: nil, source: nil, category: nil, after: nil, limit: nil)
        filters = { status:, reason:, source:, category:, after:, limit: }
        request("list", Verbs::GET, Routes::SUPPRESSIONS, object(Models::SuppressionList),
                query: query(filters, Internal::Fields::LIST_SUPPRESSIONS))
      end

      # Percorre todas as páginas de {#list}; para na primeira falha.
      #
      # @return [Enumerator::Lazy<Response>]
      def pages(**filters)
        Internal::Paginator.cursor { |after| list(**filters, after: after) }
      end

      # @param id [String]
      # @return [Response] com {Models::SuppressionDetail}
      def get(id)
        request("get", Verbs::GET, route(Routes::SUPPRESSION, id), object(Models::SuppressionDetail))
      end

      # @param id [String]
      # @return [Response] com {CoffeeMail::NO_CONTENT}
      def delete(id)
        request("delete", Verbs::DELETE, route(Routes::SUPPRESSION, id), raw)
      end

      # @param id [String]
      # @return [Response] com {CoffeeMail::NO_CONTENT}
      def reactivate(id)
        request("reactivate", Verbs::POST, route(Routes::SUPPRESSION_REACTIVATE, id), raw)
      end

      # Importa até 1000 supressões. Cada item aceita `email` e `reason`.
      #
      # @param suppressions [Array<Hash>]
      # @return [Response] com {Models::BulkSuppressionsResult}
      def bulk_create(suppressions:)
        request("bulk_create", Verbs::POST, Routes::SUPPRESSIONS_BULK, object(Models::BulkSuppressionsResult),
                body: body({ suppressions: }, Internal::Fields::SUPPRESSIONS_BULK))
      end
    end
  end
end
