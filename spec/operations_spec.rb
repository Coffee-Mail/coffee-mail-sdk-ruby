# frozen_string_literal: true

RSpec.describe "Operações do contrato" do
  OperationCases::ALL.each do |example|
    describe example.title do
      it "#{example.id} #{example.verb} #{example.path}" do
        status, reply = example.reply
        transport = FakeTransport.json(status, reply)
        response = example.call.call(client_with(transport))

        expect(response).to be_success
        expect([transport.last.http_method, transport.last_path]).to eq([example.verb, "/v1/product#{example.path}"])
        expect(transport.last_body).to eq(example.body) if example.body
        expect(transport.last.body).to be_nil unless example.body
        expect(transport.last_query).to eq(example.query || {})
        expect(example.expect_data.call(response.data)).to be(true)
      end
    end
  end

  describe "templates.preview_by_id" do
    it "RB-OPS-22 busca o template e renderiza o HTML dele" do
      transport = FakeTransport.new(FakeTransport.reply(200, OperationCases::TEMPLATE),
                                    FakeTransport.reply(200, { "html" => "<p>Ana</p>" }))
      response = client_with(transport).templates.preview_by_id("t1", variables: { nome: "Ana" })

      expect(response.data.html).to eq("<p>Ana</p>")
      expect(transport.requests.map { |request| URI(request.url).path })
        .to eq(["/v1/product/templates/t1", "/v1/product/templates/preview"])
      expect(transport.last_body).to eq("html" => "<p>{{nome}}</p>", "format" => "html",
                                        "variables" => { "nome" => "Ana" })
    end

    it "RB-OPS-22 devolve a falha do get sem chamar o preview" do
      transport = FakeTransport.json(404, { "error" => { "code" => "NOT_FOUND", "message" => "não existe" } })
      response = client_with(transport).templates.preview_by_id("t404")

      expect(response.error).to be_a(CoffeeMail::NotFoundError)
      expect(transport.requests.size).to eq(1)
    end
  end

  describe "introspecção" do
    let(:reply) { { "id" => "k1", "name" => "prod", "organisationId" => "o1", "scopes" => ["full_access"] } }

    it "RB-OPS-62 GET /auth/me/api-key com cache de 5 minutos" do
      transport = FakeTransport.json(200, reply)
      client = client_with(transport)
      first = client.introspect
      second = client.introspect

      expect(first.data.organisation_id).to eq("o1")
      expect(second).to equal(first)
      expect(transport.requests.size).to eq(1)
      expect(transport.last_path).to eq("/v1/product/auth/me/api-key")
    end

    it "RB-OPS-62 force_refresh e invalidate_api_key_cache ignoram o cache" do
      transport = FakeTransport.json(200, reply)
      client = client_with(transport)
      client.introspect
      client.introspect(force_refresh: true)
      client.invalidate_api_key_cache
      client.introspect

      expect(transport.requests.size).to eq(3)
    end

    it "RB-OPS-62 falha não é cacheada e o cache expira" do
      now = [0.0]
      transport = FakeTransport.new(FakeTransport.reply(500, ""), FakeTransport.reply(200, reply))
      options = CoffeeMail::Internal::Options.build(api_key: API_KEY, locale: "pt-BR", timeout: 1, retry_policy: nil,
                                                    transport: transport)
      requester = CoffeeMail::Internal::Requester.new(options)
      cache = CoffeeMail::Internal::IntrospectionCache.new(requester, clock: -> { now.first })

      expect(cache.fetch(force_refresh: false)).to be_failure
      expect(cache.fetch(force_refresh: false)).to be_success
      now[0] = 301.0
      cache.fetch(force_refresh: false)
      expect(transport.requests.size).to eq(3)
    end
  end
end
