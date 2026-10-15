# frozen_string_literal: true

require "coffeemail"

module Examples
  module SendEmail
    module_function

    def run(client)
      data, error = client.emails.send(
        from: { email: "app@exemplo.com.br", name: "Minha App" },
        to: "ana@exemplo.com.br",
        subject: "Bem-vinda!",
        html: "<p>Olá, Ana!</p>",
        tags: [{ name: "fluxo", value: "onboarding" }],
        idempotency_key: "boas-vindas-ana",
      )
      return "Falha (#{error.code}): #{error.message}" if error

      "E-mail #{data.id} #{data.status}"
    end
  end
end

puts Examples::SendEmail.run(CoffeeMail::Client.new) if $PROGRAM_NAME == __FILE__
