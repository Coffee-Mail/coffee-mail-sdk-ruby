# frozen_string_literal: true

module CoffeeMail
  # Idiomas suportados pelo catálogo local de mensagens e enviados em `Accept-Language`.
  module Locale
    # Português do Brasil (padrão).
    PT_BR = "pt-BR"
    # Inglês.
    EN = "en"
    # Locale usado quando nenhum é informado.
    DEFAULT = PT_BR
    # Todos os locales aceitos.
    ALL = [PT_BR, EN].freeze
  end
end
