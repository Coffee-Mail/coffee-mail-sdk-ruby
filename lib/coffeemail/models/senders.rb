# frozen_string_literal: true

module CoffeeMail
  module Models
    # Remetente verificado. `verification_token` só vem em `senders.create`.
    SenderDetail = Internal::Model.define(
      id: :string, email: :string, display_name: :string, verification_token: :string, verified_at: :time,
      active: :boolean, created_at: :time,
      masked: %i[verification_token]
    )

    # Resultado de `senders.list`.
    SenderList = Internal::Model.define(senders: [SenderDetail])

    # Resultado de `senders.verify`.
    VerifiedSender = Internal::Model.define(id: :string, email: :string)
  end
end
