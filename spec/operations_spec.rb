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

  describe "Fase 2 do contrato" do
    it "RB-OPS-69 resend_verification mapeia 409 e 404 para erros tipados" do
      conflict = FakeTransport.json(409, { "error" => { "code" => "CONFLICT", "message" => "já verificado" } })
      missing = FakeTransport.json(404, { "error" => { "code" => "NOT_FOUND", "message" => "não existe" } })

      expect(client_with(conflict).senders.resend_verification("se1").error).to be_a(CoffeeMail::ConflictError)
      expect(client_with(missing).senders.resend_verification("x").error).to be_a(CoffeeMail::NotFoundError)
    end

    it "RB-OPS-70 scheduled_at aceita String ISO 8601" do
      transport = FakeTransport.json(201, OperationCases::BROADCAST)
      client_with(transport).broadcasts.create(audience_id: "a1", from_email: "app@x.com", template_id: "t1",
                                               scheduled_at: "2030-01-01T10:00:00Z")

      expect(transport.last_body["scheduledAt"]).to eq("2030-01-01T10:00:00Z")
    end

    it "RB-OPS-71 broadcasts.get expõe metrics; ausente vira nil" do
      metrics = { "delivered" => 9, "opened" => 4, "clicked" => 1, "bounced" => 1, "failed" => 0, "suppressed" => 2 }
      with = FakeTransport.json(200, OperationCases::BROADCAST.merge("metrics" => metrics))
      without = FakeTransport.json(200, OperationCases::BROADCAST)

      expect(client_with(with).broadcasts.get("b1").data.metrics.delivered).to eq(9)
      expect(client_with(without).broadcasts.get("b1").data.metrics).to be_nil
    end

    it "RB-OPS-72 contato descadastrado e contato sem o campo" do
      page = { "contacts" => [OperationCases::CONTACT.merge("subscribed" => false), OperationCases::CONTACT],
               "total" => 2 }
      contacts = client_with(FakeTransport.json(200, page)).audiences.contacts.list("a1").data.contacts

      expect(contacts.map(&:subscribed)).to eq([false, nil])
    end

    it "RB-OPS-73 senders.create sem token na resposta deixa verification_token nil" do
      reply = { "id" => "se1", "email" => "app@x.com", "active" => false }
      created = client_with(FakeTransport.json(201, reply)).senders.create(email: "app@x.com").data

      expect(created.verification_token).to be_nil
    end
  end

  describe "Fase 4 do contrato: entregabilidade" do
    def api_error(status, code)
      FakeTransport.json(status, { "error" => { "code" => code, "message" => code } })
    end

    def time(value) = Time.iso8601(value)

    it "RB-OPS-74 rotate_dkim é idempotente e não envia corpo" do
      transport = FakeTransport.new(FakeTransport.reply(200, OperationCases::DKIM_ROTATION),
                                    FakeTransport.reply(200, OperationCases::DKIM_ROTATION))
      client = client_with(transport)
      first = client.domains.rotate_dkim("d1").data
      second = client.domains.rotate_dkim("d1").data

      expect(second).to eq(first)
      expect(first.domain_id).to eq(OperationCases::UUID)
      expect(first.record.ttl).to eq(3600)
      expect(transport.requests.map(&:body)).to eq([nil, nil])
    end

    it "RB-OPS-74 rotate_dkim mapeia 404 e 409 para erros tipados com api_code" do
      missing = client_with(api_error(404, "DOMAIN_NOT_FOUND")).domains.rotate_dkim("x").error
      pending = client_with(api_error(409, "DOMAIN_NOT_VERIFIED")).domains.rotate_dkim("d1").error

      expect([missing.class, missing.api_code]).to eq([CoffeeMail::NotFoundError, "DOMAIN_NOT_FOUND"])
      expect([pending.class, pending.api_code]).to eq([CoffeeMail::ConflictError, "DOMAIN_NOT_VERIFIED"])
    end

    it "RB-OPS-75 set_tracking_domain mapeia 400, 409 e 404 para erros tipados" do
      invalid = client_with(api_error(400, "INVALID_TRACKING_HOST")).domains.set_tracking_domain("d1", host: "x")
      disabled = client_with(api_error(409, "TRACKING_DOMAINS_DISABLED"))
                 .domains.set_tracking_domain("d1", host: "links.x.com")
      missing = client_with(api_error(404, "DOMAIN_NOT_FOUND")).domains.set_tracking_domain("x", host: "links.x.com")

      expect([invalid.error.class, invalid.error.api_code])
        .to eq([CoffeeMail::ValidationError, "INVALID_TRACKING_HOST"])
      expect([disabled.error.class, disabled.error.api_code])
        .to eq([CoffeeMail::ConflictError, "TRACKING_DOMAINS_DISABLED"])
      expect(missing.error).to be_a(CoffeeMail::NotFoundError)
    end

    it "RB-OPS-75 set_tracking_domain verificado traz verified_at como Time" do
      reply = OperationCases::TRACKING.merge("verified" => true, "verifiedAt" => OperationCases::T0)
      data = client_with(FakeTransport.json(200, reply)).domains.set_tracking_domain("d1", host: "links.x.com").data

      expect([data.verified, data.verified_at]).to eq([true, time(OperationCases::T0)])
    end

    it "RB-OPS-76 remove_tracking_domain sem domínio configurado devolve nil" do
      empty = client_with(FakeTransport.json(200, "")).domains.remove_tracking_domain("d1")
      null = client_with(FakeTransport.json(200, nil)).domains.remove_tracking_domain("d1")
      missing = client_with(api_error(404, "DOMAIN_NOT_FOUND")).domains.remove_tracking_domain("x")

      expect([empty, null]).to all(be_success)
      expect([empty.data, null.data]).to eq([nil, nil])
      expect(missing.error).to be_a(CoffeeMail::NotFoundError)
    end

    it "RB-OPS-77 domains.get expõe rotação de DKIM, return-path e domínio de rastreamento" do
      reply = OperationCases::DOMAIN.merge("dkimRotation" => OperationCases::DKIM_ROTATION,
                                           "returnPath" => OperationCases::TRACKING.merge("host" => "bounce.x.com"),
                                           "trackingDomain" => OperationCases::TRACKING,
                                           "trackingDomainsAvailable" => true)
      data = client_with(FakeTransport.json(200, reply)).domains.get("d1").data

      expect(data.dkim_rotation.selector).to eq("cm2")
      expect(data.return_path.host).to eq("bounce.x.com")
      expect(data.tracking_domain.target).to eq("track.coffeemail.com.br")
      expect(data.tracking_domains_available).to be(true)
    end

    it "RB-OPS-77 campos novos nulos ou ausentes viram nil" do
      reply = OperationCases::DOMAIN.merge("dkimRotation" => nil, "returnPath" => nil, "trackingDomain" => nil)
      data = client_with(FakeTransport.json(200, reply)).domains.get("d1").data
      members = data.to_h.slice(:dkim_rotation, :return_path, :tracking_domain, :tracking_domains_available)

      expect(members.values).to eq([nil, nil, nil, nil])
      expect(CoffeeMail::Models::DomainDetail.members.last(4))
        .to eq(%i[dkim_rotation return_path tracking_domain tracking_domains_available])
    end

    it "RB-OPS-78 get_warmup_status expõe status, total_days, started_at e completed_at" do
      warming = { "domainId" => OperationCases::UUID, "status" => "warming", "currentDay" => 3, "dailyQuota" => 200,
                  "sentToday" => 50, "remainingToday" => 150, "quotaUsedPercent" => 25, "lastSendDate" => nil,
                  "totalDays" => 30, "startedAt" => OperationCases::T0, "completedAt" => nil }
      completed = warming.merge("status" => "completed", "completedAt" => "2026-11-13T10:00:00.000Z")
      transport = FakeTransport.new(FakeTransport.reply(200, warming), FakeTransport.reply(200, completed))
      client = client_with(transport)
      first = client.domains.get_warmup_status("d1").data
      last = client.domains.get_warmup_status("d1").data

      expect([first.status, first.total_days, first.started_at, first.completed_at])
        .to eq([CoffeeMail::DomainWarmupStatus::WARMING, 30, time(OperationCases::T0), nil])
      expect([last.status, last.completed_at])
        .to eq([CoffeeMail::DomainWarmupStatus::COMPLETED, time("2026-11-13T10:00:00.000Z")])
    end

    it "RB-OPS-78 get_warmup_status com JSON null vira nil com sucesso" do
      response = client_with(FakeTransport.json(200, nil)).domains.get_warmup_status("d1")

      expect(response).to be_success
      expect(response.data).to be_nil
    end

    it "RB-OPS-79 enums de aquecimento e de tipo de registro são abertos" do
      expect(CoffeeMail::DomainWarmupStatus::ALL).to eq(%w[warming completed])
      expect(CoffeeMail::DnsRecordType::ALL).to eq(%w[TXT CNAME])
      reply = OperationCases::DKIM_ROTATION.merge("record" => OperationCases::RECORD.merge("type" => "MX"))
      unknown = client_with(FakeTransport.json(200, reply)).domains.rotate_dkim("d1").data

      expect(unknown.record.type).to eq("MX")
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
