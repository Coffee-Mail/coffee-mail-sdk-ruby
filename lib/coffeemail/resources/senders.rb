# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Remetentes verificados (`/v1/product/senders`).
    class Senders < Base
      include Internal::Constants

      # @return [Response] com {Models::SenderDetail}
      def create(email:, display_name: nil)
        request("create", Verbs::POST, Routes::SENDERS, object(Models::SenderDetail),
                body: body({ email:, display_name: }, Internal::Fields::SENDER))
      end

      # @return [Response] com {Models::SenderList}
      def list
        request("list", Verbs::GET, Routes::SENDERS, object(Models::SenderList))
      end

      # Confirma o remetente com o token recebido por e-mail.
      #
      # @param token [String]
      # @return [Response] com {Models::VerifiedSender}
      def verify(token:)
        request("verify", Verbs::POST, Routes::SENDERS_VERIFY, object(Models::VerifiedSender),
                body: body({ token: }, Internal::Fields::SENDER_VERIFY))
      end

      # Reenvia o e-mail de verificação com um token novo; o anterior expira.
      #
      # @param id [String]
      # @return [Response] com {CoffeeMail::NO_CONTENT}
      def resend_verification(id)
        request("resend_verification", Verbs::POST, route(Routes::SENDER_RESEND_VERIFICATION, id), raw)
      end

      # @param id [String]
      # @return [Response] com {CoffeeMail::NO_CONTENT}
      def delete(id)
        request("delete", Verbs::DELETE, route(Routes::SENDER, id), raw)
      end
    end
  end
end
