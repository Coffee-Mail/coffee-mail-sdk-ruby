# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Domínios de envio (`/v1/product/domains`).
    class Domains < Base
      include Internal::Constants

      # @param name [String] domínio, ex.: `"exemplo.com.br"`
      # @return [Response] com {Models::CreatedDomain}
      def create(name:)
        request("create", Verbs::POST, Routes::DOMAINS, object(Models::CreatedDomain),
                body: body({ name: }, Internal::Fields::DOMAIN))
      end

      # @return [Response] com {Models::DomainList}
      def list
        request("list", Verbs::GET, Routes::DOMAINS, object(Models::DomainList))
      end

      # @param id [String]
      # @return [Response] com {Models::DomainDetail}
      def get(id)
        request("get", Verbs::GET, route(Routes::DOMAIN, id), object(Models::DomainDetail))
      end

      # Dispara a verificação DNS.
      #
      # @param id [String]
      # @return [Response] com {Models::DomainVerification}
      def verify(id)
        request("verify", Verbs::POST, route(Routes::DOMAIN_VERIFY, id), object(Models::DomainVerification))
      end

      # Remove o domínio. Com chave de API, a remoção não exige reautenticação.
      #
      # @param id [String]
      # @return [Response] com {Models::DeletedDomain}
      def delete(id)
        request("delete", Verbs::DELETE, route(Routes::DOMAIN, id), object(Models::DeletedDomain))
      end

      # @param id [String]
      # @return [Response] com {Models::DomainHealth}
      def get_health(id)
        request("get_health", Verbs::POST, route(Routes::DOMAIN_HEALTH, id), object(Models::DomainHealth))
      end

      # Status do aquecimento. `data` é `nil` quando o domínio não está em aquecimento.
      #
      # @param id [String]
      # @return [Response] com {Models::DomainWarmup} ou `nil`
      def get_warmup_status(id)
        request("get_warmup_status", Verbs::GET, route(Routes::DOMAIN_WARMUP, id), object(Models::DomainWarmup),
                empty: nil)
      end
    end
  end
end
