# frozen_string_literal: true

module CoffeeMail
  # Cliente da API CoffeeMail. Imutável e seguro para uso entre threads.
  #
  # A URL da API é fixa (`https://api.coffeemail.com.br`): não há como trocá-la, para que a chave de API
  # nunca seja enviada a outro host. Para testes, proxy ou instrumentação, injete um `transport:`.
  #
  # @example
  #   client = CoffeeMail::Client.new(api_key: ENV.fetch("COFFEEMAIL_API_KEY"))
  #   data, error = client.emails.send(from: "app@exemplo.com", to: "ana@exemplo.com", subject: "Oi", text: "Oi")
  class Client
    # @return [Resources::Emails]
    attr_reader :emails
    # @return [Resources::Domains]
    attr_reader :domains
    # @return [Resources::Templates]
    attr_reader :templates
    # @return [Resources::Audiences]
    attr_reader :audiences
    # @return [Resources::Broadcasts]
    attr_reader :broadcasts
    # @return [Resources::Senders]
    attr_reader :senders
    # @return [Resources::Suppressions]
    attr_reader :suppressions
    # @return [Resources::Webhooks]
    attr_reader :webhooks
    # @return [Resources::Stats]
    attr_reader :stats

    # @param api_key [String, nil] chave `cm_live_...`/`cm_test_...`; sem ela, usa `COFFEEMAIL_API_KEY`
    # @param locale [String] {Locale::PT_BR} (padrão) ou {Locale::EN}
    # @param timeout [Numeric] segundos por tentativa (padrão 10)
    # @param retry_policy [RetryPolicy, nil] novas tentativas automáticas (desligadas por padrão)
    # @param transport [#call, nil] recebe {HttpRequest} e devolve {HttpResponse}
    # @raise [MissingApiKeyError] sem chave de API
    # @raise [ArgumentError] com opção inválida
    def initialize(api_key: nil, locale: Locale::DEFAULT, timeout: Internal::Constants::Defaults::TIMEOUT_SECONDS,
                   retry_policy: nil, transport: nil)
      @options = Internal::Options.build(api_key: api_key, locale: locale, timeout: timeout,
                                         retry_policy: retry_policy, transport: transport)
      requester = Internal::Requester.new(@options)
      @introspection = Internal::IntrospectionCache.new(requester)
      build_resources(requester)
      freeze
    end

    # Dados da chave de API em uso, com cache local de 5 minutos.
    #
    # @param force_refresh [Boolean] ignora o cache
    # @return [Response] com {Models::ApiKeyInfo}
    def introspect(force_refresh: false)
      @introspection.fetch(force_refresh: force_refresh)
    end

    # Descarta o cache de {#introspect}.
    #
    # @return [void]
    def invalidate_api_key_cache
      @introspection.invalidate
      nil
    end

    # @return [String]
    def locale = @options.locale

    # @return [Numeric]
    def timeout = @options.timeout

    # @return [String]
    def inspect
      "#<CoffeeMail::Client api_key=#{@options.masked_key} locale=#{locale} timeout=#{timeout}>"
    end

    # @return [String]
    def to_s = inspect

    private

    def build_resources(requester)
      @emails = Resources::Emails.new(requester)
      @domains = Resources::Domains.new(requester)
      @templates = Resources::Templates.new(requester)
      @audiences = Resources::Audiences.new(requester)
      @broadcasts = Resources::Broadcasts.new(requester)
      @senders = Resources::Senders.new(requester)
      @suppressions = Resources::Suppressions.new(requester)
      @webhooks = Resources::Webhooks.new(requester)
      @stats = Resources::Stats.new(requester)
    end
  end
end
