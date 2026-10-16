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
        request("get_warmup_status", Verbs::GET, route(Routes::DOMAIN_WARMUP, id), optional(Models::DomainWarmup),
                empty: nil)
      end

      # Inicia a rotação da chave DKIM. A chave em uso só muda quando o registro TXT do novo seletor
      # for encontrado no DNS. Idempotente: com uma rotação pendente, devolve a mesma rotação.
      #
      # @param id [String]
      # @return [Response] com {Models::DkimRotation}; 404 vira {NotFoundError} e 409 (domínio não
      #   verificado) vira {ConflictError}
      def rotate_dkim(id)
        request("rotate_dkim", Verbs::POST, route(Routes::DOMAIN_DKIM_ROTATE, id), object(Models::DkimRotation))
      end

      # Define o domínio de rastreamento (subdomínio usado nos links de abertura e clique).
      #
      # @param id [String]
      # @param host [String] subdomínio do domínio de envio, ex.: `"links.exemplo.com.br"`
      # @return [Response] com {Models::CustomHostStatus}; host inválido vira {ValidationError} e o recurso
      #   desabilitado vira {ConflictError}
      def set_tracking_domain(id, host:)
        request("set_tracking_domain", Verbs::PUT, route(Routes::DOMAIN_TRACKING, id),
                object(Models::CustomHostStatus), body: body({ host: }, Internal::Fields::TRACKING_DOMAIN))
      end

      # Remove o domínio de rastreamento. `data` é `nil` quando não havia domínio configurado.
      #
      # @param id [String]
      # @return [Response] com {Models::CustomHostStatus} ou `nil`
      def remove_tracking_domain(id)
        request("remove_tracking_domain", Verbs::DELETE, route(Routes::DOMAIN_TRACKING, id),
                optional(Models::CustomHostStatus), empty: nil)
      end
    end
  end
end
