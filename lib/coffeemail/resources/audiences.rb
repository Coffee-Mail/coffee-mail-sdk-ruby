# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Audiências (`/v1/product/audiences`). Os contatos ficam em {#contacts}.
    class Audiences < Base
      include Internal::Constants

      # @return [Contacts]
      attr_reader :contacts

      # @api private
      def initialize(requester)
        @contacts = Contacts.new(requester)
        super
      end

      # @return [Response] com {Models::AudienceDetail}
      def create(name:, description: nil)
        request("create", Verbs::POST, Routes::AUDIENCES, object(Models::AudienceDetail),
                body: body({ name:, description: }, Internal::Fields::AUDIENCE))
      end

      # Uma página de audiências (paginação por offset).
      #
      # @return [Response] com {Models::AudienceList}
      def list(limit: nil, offset: nil)
        request("list", Verbs::GET, Routes::AUDIENCES, object(Models::AudienceList),
                query: query({ limit:, offset: }, Internal::Fields::OFFSET_PAGE))
      end

      # Percorre todas as páginas de {#list}; para na primeira falha.
      #
      # @return [Enumerator::Lazy<Response>]
      def pages(limit: nil, offset: 0)
        Internal::Paginator.offset(offset) { |current| list(limit: limit, offset: current) }
      end

      # @param id [String]
      # @return [Response] com {Models::AudienceDetail}
      def get(id)
        request("get", Verbs::GET, route(Routes::AUDIENCE, id), object(Models::AudienceDetail))
      end

      # @param id [String]
      # @return [Response] com {Models::UpdatedResource}
      def update(id, name: nil, description: nil, active: nil)
        request("update", Verbs::PUT, route(Routes::AUDIENCE, id), object(Models::UpdatedResource),
                body: body({ name:, description:, active: }, Internal::Fields::AUDIENCE))
      end

      # @param id [String]
      # @return [Response] com {CoffeeMail::NO_CONTENT}
      def delete(id)
        request("delete", Verbs::DELETE, route(Routes::AUDIENCE, id), raw)
      end
    end

    # Contatos de uma audiência (`/v1/product/audiences/{id}/contacts`).
    class Contacts < Base
      include Internal::Constants

      # @param audience_id [String]
      # @return [Response] com {Models::Contact}
      def create(audience_id, email:, first_name: nil, last_name: nil, metadata: nil)
        request("create", Verbs::POST, route(Routes::CONTACTS, audience_id), object(Models::Contact),
                body: body({ email:, first_name:, last_name:, metadata: }, Internal::Fields::CONTACT))
      end

      # Uma página de contatos (paginação por offset), com `total`.
      #
      # @param audience_id [String]
      # @return [Response] com {Models::ContactList}
      def list(audience_id, limit: nil, offset: nil)
        request("list", Verbs::GET, route(Routes::CONTACTS, audience_id), object(Models::ContactList),
                query: query({ limit:, offset: }, Internal::Fields::OFFSET_PAGE))
      end

      # Percorre todas as páginas de {#list}; para na primeira falha.
      #
      # @param audience_id [String]
      # @return [Enumerator::Lazy<Response>]
      def pages(audience_id, limit: nil, offset: 0)
        Internal::Paginator.offset(offset) { |current| list(audience_id, limit: limit, offset: current) }
      end

      # Adiciona até 10 000 contatos. Cada item aceita `email`, `first_name`, `last_name` e `metadata`.
      #
      # @param audience_id [String]
      # @param contacts [Array<Hash>]
      # @return [Response] com {Models::BulkAddContactsResult}
      def bulk_add(audience_id, contacts:)
        request("bulk_add", Verbs::POST, route(Routes::CONTACTS_BULK, audience_id),
                object(Models::BulkAddContactsResult), body: body({ contacts: }, Internal::Fields::CONTACTS_BULK))
      end

      # @param audience_id [String]
      # @param contact_id [String]
      # @return [Response] com {Models::UpdatedResource}
      def update(audience_id, contact_id, first_name: nil, last_name: nil, metadata: nil)
        request("update", Verbs::PUT, route(Routes::CONTACT, audience_id, contact_id),
                object(Models::UpdatedResource),
                body: body({ first_name:, last_name:, metadata: }, Internal::Fields::CONTACT))
      end

      # @param audience_id [String]
      # @param contact_id [String]
      # @return [Response] com {CoffeeMail::NO_CONTENT}
      def delete(audience_id, contact_id)
        request("delete", Verbs::DELETE, route(Routes::CONTACT, audience_id, contact_id), raw)
      end

      private

      def resource_name = "audiences.contacts"
    end
  end
end
