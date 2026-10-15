# frozen_string_literal: true

RSpec.describe CoffeeMail::Client do
  let(:transport) do
    FakeTransport.json(200, { "id" => "k1", "name" => "prod", "organisationId" => "o1", "scopes" => [] })
  end

  describe "construção" do
    it "RB-CLI-01 aceita api_key, locale, timeout, retry_policy e transport" do
      client = described_class.new(api_key: API_KEY, locale: "en", timeout: 3,
                                   retry_policy: CoffeeMail::RetryPolicy.new(max_attempts: 2), transport: transport)

      expect(client.locale).to eq("en")
      expect(client.timeout).to eq(3)
    end

    it "RB-CLI-01 rejeita base_url" do
      expect { described_class.new(api_key: API_KEY, base_url: "https://evil.example") }
        .to raise_error(ArgumentError, /base_url/)
    end

    it "RB-CLI-02 usa COFFEEMAIL_API_KEY quando a chave não é informada" do
      stub_const("ENV", ENV.to_h.merge("COFFEEMAIL_API_KEY" => "cm_test_from_env"))
      client = described_class.new(transport: transport)
      client.introspect

      expect(transport.last.headers["authorization"]).to eq("Bearer cm_test_from_env")
    end

    it "RB-CLI-02 prefere a chave informada à variável de ambiente" do
      stub_const("ENV", ENV.to_h.merge("COFFEEMAIL_API_KEY" => "cm_test_from_env"))
      client_with(transport).introspect

      expect(transport.last.headers["authorization"]).to eq("Bearer #{API_KEY}")
    end

    it "RB-CLI-03 sem chave levanta MissingApiKeyError com a mensagem do locale" do
      stub_const("ENV", ENV.to_h.except("COFFEEMAIL_API_KEY"))

      expect { described_class.new }.to raise_error(CoffeeMail::MissingApiKeyError, /A chave de API não foi informada/)
      expect { described_class.new(api_key: "   ", locale: "en") }
        .to raise_error(CoffeeMail::MissingApiKeyError, /API key was not provided/) { |error|
          expect(error.code).to eq("MISSING_API_KEY")
        }
    end

    it "RB-CLI-03 não valida o formato da chave" do
      expect { described_class.new(api_key: "qualquer-coisa", transport: transport) }.not_to raise_error
    end

    it "RB-CLI-04 aceita pt-BR e en e rejeita outros locales" do
      expect(client_with(transport).locale).to eq(CoffeeMail::Locale::PT_BR)
      expect(client_with(transport, locale: CoffeeMail::Locale::EN).locale).to eq("en")
      expect { client_with(transport, locale: "es") }.to raise_error(ArgumentError, /Locale inválido/)
    end

    it "RB-CLI-05 timeout padrão de 10 s e rejeita valores não positivos" do
      expect(client_with(transport).timeout).to eq(10)
      expect { client_with(transport, timeout: 0) }.to raise_error(ArgumentError)
      expect { client_with(transport, timeout: "10") }.to raise_error(ArgumentError)
    end

    it "RB-CLI-05 rejeita retry_policy e transport inválidos" do
      expect { client_with(transport, retry_policy: 3) }.to raise_error(ArgumentError, /RetryPolicy/)
      expect { described_class.new(api_key: API_KEY, transport: Object.new) }.to raise_error(ArgumentError, /call/)
    end
  end

  it "RB-CLI-06 client congelado e seguro entre threads" do
    client = client_with(transport)
    threads = Array.new(8) { Thread.new { client.introspect(force_refresh: true).success? } }

    expect(client).to be_frozen
    expect(client.emails).to be_frozen
    expect(threads.map(&:value)).to all(be(true))
  end

  it "RB-CLI-07 inspect e to_s não expõem a chave" do
    client = client_with(transport)

    expect(client.inspect).to include("cm_test_****")
    expect(client.inspect).not_to include(API_KEY)
    expect(client.to_s).not_to include(API_KEY[8..])
  end

  it "RB-CLI-08 expõe os recursos do contrato" do
    client = client_with(transport)
    resources = %i[emails domains templates audiences broadcasts senders suppressions webhooks stats]

    expect(resources.map { |name| client.public_send(name).class.name.split("::").last })
      .to eq(%w[Emails Domains Templates Audiences Broadcasts Senders Suppressions Webhooks Stats])
    expect(client.audiences.contacts).to be_a(CoffeeMail::Resources::Contacts)
  end

  it "RB-CLI-09 VERSION é a origem do gemspec" do
    spec = Gem::Specification.load(File.expand_path("../coffeemail.gemspec", __dir__))

    expect(spec.version.to_s).to eq(CoffeeMail::VERSION)
  end
end
