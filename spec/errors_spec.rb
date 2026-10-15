# frozen_string_literal: true

RSpec.describe "Envelope e erros" do
  def response_for(status, body, headers: {}, resource: :emails)
    client = client_with(FakeTransport.json(status, body, headers))
    resource == :broadcasts ? client.broadcasts.get("b1") : client.emails.get("e1")
  end

  def api_error(code, message = "falhou", meta: nil, details: nil)
    { "error" => { "code" => code, "message" => message, "meta" => meta, "details" => details }.compact }
  end

  describe CoffeeMail::Response do
    it "RB-ERR-01 traz data ou error, nunca os dois" do
      success = response_for(200, { "id" => "e1" })
      failure = response_for(404, api_error("NOT_FOUND"))

      expect([success.success?, success.failure?, success.error, success.status]).to eq([true, false, nil, 200])
      expect([failure.success?, failure.failure?, failure.data, failure.status]).to eq([false, true, nil, 404])
    end

    it "RB-ERR-02 desestrutura com to_ary e deconstruct_keys" do
      data, error = response_for(200, { "id" => "e1" })
      response_for(404, api_error("NOT_FOUND")) => { error: matched_error }

      expect(data.id).to eq("e1")
      expect(error).to be_nil
      expect(matched_error).to be_a(CoffeeMail::NotFoundError)
    end

    it "RB-ERR-03 unwrap! devolve data no sucesso e levanta o erro na falha" do
      expect(response_for(200, { "id" => "e1" }).unwrap!.id).to eq("e1")
      expect { response_for(409, api_error("CONFLICT")).unwrap! }.to raise_error(CoffeeMail::ConflictError, "falhou")
    end

    it "RB-ERR-03 nenhuma operação levanta exceção por erro de API ou de rede" do
      failing = client_with(FakeTransport.new(Errno::ECONNRESET.new))

      expect { failing.emails.get("e1") }.not_to raise_error
      expect { response_for(500, "boom") }.not_to raise_error
    end
  end

  it "RB-ERR-04 erro expõe status, code, api_code, message, details e request_id" do
    error = response_for(400, api_error("VALIDATION_FAILED", "inválido", meta: { "issues" => [] }),
                         headers: { "x-request-id" => "req-1" }).error

    expect([error.status, error.code, error.api_code, error.message, error.request_id])
      .to eq([400, "VALIDATION_ERROR", "VALIDATION_FAILED", "inválido", "req-1"])
    expect(error.details).to eq("issues" => []).and be_frozen
    expect(error).to be_a(StandardError)
  end

  it "RB-ERR-05 mapeia cada status para a classe e o código canônico" do
    table = {
      400 => [CoffeeMail::ValidationError, "VALIDATION_ERROR"],
      401 => [CoffeeMail::AuthenticationError, "UNAUTHORIZED"],
      402 => [CoffeeMail::PaymentRequiredError, "PAYMENT_REQUIRED"],
      403 => [CoffeeMail::ForbiddenError, "FORBIDDEN"],
      404 => [CoffeeMail::NotFoundError, "NOT_FOUND"],
      409 => [CoffeeMail::ConflictError, "CONFLICT"],
      429 => [CoffeeMail::RateLimitError, "RATE_LIMIT_EXCEEDED"],
      500 => [CoffeeMail::InternalServerError, "INTERNAL_SERVER_ERROR"],
      502 => [CoffeeMail::InternalServerError, "INTERNAL_SERVER_ERROR"],
      503 => [CoffeeMail::InternalServerError, "INTERNAL_SERVER_ERROR"],
      504 => [CoffeeMail::InternalServerError, "INTERNAL_SERVER_ERROR"],
    }

    table.each do |status, (klass, code)|
      error = response_for(status, api_error("X")).error
      expect([error.class, error.code]).to eq([klass, code]), "status #{status}"
    end
  end

  it "RB-ERR-06 outro status usa o código da API ou API_ERROR" do
    with_code = response_for(418, api_error("TEAPOT")).error
    without_code = response_for(422, { "message" => "não processável" }).error

    expect([with_code.class, with_code.code]).to eq([CoffeeMail::Error, "TEAPOT"])
    expect([without_code.code, without_code.message]).to eq(["API_ERROR", "não processável"])
  end

  it "RB-ERR-07 401 sem message usa o catálogo local" do
    pt = response_for(401, { "error" => { "code" => "UNAUTHENTICATED" } }).error
    en = client_with(FakeTransport.json(401, { "error" => { "code" => "UNAUTHENTICATED" } }), locale: "en")
         .emails.get("e1").error

    expect(pt.message).to eq("Ocorreu um erro inesperado durante a comunicação com a API do CoffeeMail.")
    expect(en.message).to eq("An unexpected error occurred while communicating with CoffeeMail API.")
  end

  it "RB-ERR-07 corpo não JSON usa o corpo bruto; vazio usa o catálogo" do
    raw = response_for(502, "Bad Gateway do proxy").error
    empty = response_for(503, "").error
    rate_limited = response_for(429, "").error

    expect(raw.message).to eq("Bad Gateway do proxy")
    expect(empty.message).to eq("Ocorreu um erro inesperado durante a comunicação com a API do CoffeeMail.")
    expect(rate_limited.message)
      .to eq("Limite de requisições excedido (Rate Limit). Tente novamente em alguns segundos.")
  end

  it "RB-ERR-08 preserva api_code e mescla meta com details" do
    error = response_for(429, api_error("PLAN_QUOTA_EXCEEDED", meta: { "a" => 1 }, details: { "b" => 2 })).error

    expect(error.api_code).to eq("PLAN_QUOTA_EXCEEDED")
    expect(error.code).to eq("RATE_LIMIT_EXCEEDED")
    expect(error.details).to eq("a" => 1, "b" => 2)
  end

  it "RB-ERR-08 ignora meta e details que não são objetos" do
    error = response_for(400, { "error" => { "code" => "X", "meta" => "texto", "details" => [1] } }).error

    expect(error.details).to eq({})
  end

  it "RB-ERR-09 request_id vem do header x-request-id" do
    expect(response_for(404, api_error("NOT_FOUND"),
                        headers: { "x-request-id" => "abc" }).error.request_id).to eq("abc")
    expect(response_for(404, api_error("NOT_FOUND")).error.request_id).to be_nil
  end

  it "RB-ERR-10 retry_after_seconds vem de Retry-After; inválido vira nil" do
    valid = response_for(429, api_error("RATE_LIMIT_EXCEEDED"), headers: { "retry-after" => "60" }).error
    invalid = response_for(429, api_error("RATE_LIMIT_EXCEEDED"), headers: { "retry-after" => "amanhã" }).error
    missing = response_for(429, api_error("RATE_LIMIT_EXCEEDED")).error

    expect([valid.retry_after_seconds, invalid.retry_after_seconds, missing.retry_after_seconds]).to eq([60, nil, nil])
  end

  it "RB-ERR-11 403 em broadcasts vira PermissionError com full_access" do
    error = response_for(403, api_error("FORBIDDEN", "proibido"), resource: :broadcasts).error

    expect(error).to be_a(CoffeeMail::PermissionError).and be_a(CoffeeMail::ForbiddenError)
    expect([error.code, error.required_permission,
            error.api_code]).to eq(%w[PERMISSION_DENIED full_access FORBIDDEN])
    expect(error.details).to include("operation" => "broadcasts.get", "requiredPermission" => "full_access")
    expect(error.message).to include("(full_access (called by broadcasts.get))")
  end

  it "RB-ERR-11 403 fora de broadcasts continua ForbiddenError" do
    error = response_for(403, api_error("FORBIDDEN")).error

    expect(error.class).to eq(CoffeeMail::ForbiddenError)
    expect(error.code).to eq("FORBIDDEN")
  end

  it "RB-ERR-12 catálogo igual ao SDK Java, trocando só o construtor" do
    catalog = CoffeeMail::Internal::I18n
    keys = %i[MISSING_API_KEY REQUEST_TIMEOUT NETWORK_ERROR UNEXPECTED_ERROR INVALID_JSON RATE_LIMIT_EXCEEDED
              PERMISSION_DENIED]

    expect(catalog::PT_BR.keys).to include(*keys)
    expect(catalog::EN.keys).to match_array(catalog::PT_BR.keys)
    expect(catalog.message("pt-BR", :REQUEST_TIMEOUT, timeoutMs: 1500))
      .to eq("A requisição excedeu o tempo limite configurado de 1500ms.")
    expect(catalog.message("en", :PERMISSION_DENIED, requiredPermission: "full_access"))
      .to eq("This API key lacks the required permission (full_access) for this operation. " \
             "Create a key with 'full_access' permission in the dashboard.")
    expect(catalog.message("pt-BR", :MISSING_API_KEY)).to include("CoffeeMail::Client.new")
  end

  it "RB-ERR-12 mensagem do servidor passa intacta e locale desconhecido cai no padrão" do
    expect(response_for(400, api_error("X", "Campo 'to' obrigatório")).error.message).to eq("Campo 'to' obrigatório")
    expect(CoffeeMail::Internal::I18n.message("xx", :INVALID_JSON)).to include("JSON válido")
  end

  it "RB-ERR-13 inspect de erro e de request não contém a chave" do
    transport = FakeTransport.json(500, api_error("BOOM"))
    error = client_with(transport).emails.get("e1").error

    expect(error.inspect).not_to include(API_KEY)
    expect(error.inspect).to include("status=500 code=INTERNAL_SERVER_ERROR")
    expect(transport.last.inspect).not_to include(API_KEY)
  end
end
