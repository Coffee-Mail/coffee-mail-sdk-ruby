# frozen_string_literal: true

require_relative "lib/coffeemail/version"

Gem::Specification.new do |spec|
  spec.name = "coffeemail"
  spec.version = CoffeeMail::VERSION
  spec.authors = ["CoffeeMail"]
  spec.summary = "SDK oficial do CoffeeMail para Ruby: e-mail transacional, erros tipados e webhooks verificados."
  spec.description = "Cliente Ruby da API CoffeeMail com as 61 operações do contrato público, envelope com " \
                     "erros tipados, mensagens em pt-BR e en, e verificador de webhooks. Sem dependências de runtime."
  spec.homepage = "https://github.com/Coffee-Mail/coffee-mail-sdk-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "https://coffeemail.com.br/pt-BR/docs/sdk/ruby",
    "rubygems_mfa_required" => "true",
  }

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
