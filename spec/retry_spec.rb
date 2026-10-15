# frozen_string_literal: true

RSpec.describe "Retry opt-in" do
  let(:sleeps) { [] }
  let(:random) { instance_double(Random, rand: 0.5) }
  let(:server_error) { FakeTransport.reply(503, { "error" => { "code" => "UNAVAILABLE" } }) }
  let(:ok) { FakeTransport.reply(200, { "id" => "e1" }) }
  let(:accepted) { FakeTransport.reply(202, { "id" => "e1", "status" => "queued" }) }

  def requester_for(transport, policy)
    options = CoffeeMail::Internal::Options.build(api_key: API_KEY, locale: "pt-BR", timeout: 1, retry_policy: policy,
                                                  transport: transport)
    CoffeeMail::Internal::Requester.new(options, sleeper: ->(seconds) { sleeps << seconds }, random: random)
  end

  def operation(verb, idempotent_post: false, headers: {})
    CoffeeMail::Internal::Operation.build(name: "emails.test", http_method: verb, path: "/emails",
                                          decoder: CoffeeMail::Internal::Model::RAW, idempotent_post: idempotent_post,
                                          headers: headers)
  end

  def policy(**options) = CoffeeMail::RetryPolicy.new(max_attempts: 3, **options)

  it "RB-DX-01 sem retry_policy faz uma única tentativa" do
    transport = FakeTransport.new(server_error, ok)
    response = client_with(transport).emails.get("e1")

    expect(response.error).to be_a(CoffeeMail::InternalServerError)
    expect(transport.requests.size).to eq(1)
  end

  it "RB-DX-02 RetryPolicy valida os parâmetros e liga com max_attempts > 1" do
    expect(CoffeeMail::RetryPolicy.new(max_attempts: 1)).not_to be_enabled
    expect(policy).to be_enabled
    expect(policy.inspect).to include("max_attempts=3")
    expect { CoffeeMail::RetryPolicy.new(max_attempts: 0) }.to raise_error(ArgumentError, /max_attempts/)
    expect { CoffeeMail::RetryPolicy.new(max_attempts: 2, base_delay: -1) }.to raise_error(ArgumentError, /base_delay/)
    expect { CoffeeMail::RetryPolicy.new(max_attempts: 2, base_delay: 5, max_delay: 1) }
      .to raise_error(ArgumentError, /max_delay/)
  end

  it "RB-DX-02 retry_policy no client retenta GET até ter sucesso" do
    transport = FakeTransport.new(server_error, server_error, ok)
    response = client_with(transport, retry_policy: CoffeeMail::RetryPolicy.new(max_attempts: 3, base_delay: 0.001,
                                                                                max_delay: 0.001)).emails.get("e1")

    expect(response).to be_success
    expect(transport.requests.size).to eq(3)
  end

  it "RB-DX-03 retenta rede, 5xx e 429 de throttling, mas não cota do plano nem 4xx" do
    network = FakeTransport.new(Errno::ECONNRESET.new, ok)
    throttled = FakeTransport.new(FakeTransport.reply(429, { "error" => { "code" => "RATE_LIMIT_EXCEEDED" } }), ok)
    quota = FakeTransport.new(FakeTransport.reply(429, { "error" => { "code" => "PLAN_QUOTA_EXCEEDED" } }), ok)
    invalid = FakeTransport.new(FakeTransport.reply(400, { "error" => { "code" => "VALIDATION_FAILED" } }), ok)

    [network, throttled, quota, invalid].each { |transport| requester_for(transport, policy).call(operation("GET")) }

    expect([network, throttled, quota, invalid].map { |transport| transport.requests.size }).to eq([2, 2, 1, 1])
  end

  it "RB-DX-04 POST sem idempotência não é retentado" do
    transport = FakeTransport.new(server_error, ok)
    requester_for(transport, policy).call(operation("POST"))

    expect(transport.requests.size).to eq(1)
  end

  it "RB-DX-04 envio gera UUID de idempotência antes da 1ª tentativa e reutiliza" do
    transport = FakeTransport.new(server_error, accepted)
    client = client_with(transport, retry_policy: CoffeeMail::RetryPolicy.new(max_attempts: 2, base_delay: 0.001))
    client.emails.send(from: "app@x.com", to: "a@x.com", subject: "Oi", text: "Oi")
    keys = transport.requests.map { |request| request.headers["x-idempotency-key"] }

    expect(keys.uniq.size).to eq(1)
    expect(keys.first).to match(/\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/)
  end

  it "RB-DX-04 chave informada pelo usuário é preservada e sem retry não há chave gerada" do
    transport = FakeTransport.new(server_error, accepted)
    requester_for(transport, policy).call(operation("POST", idempotent_post: true,
                                                            headers: { "x-idempotency-key" => "minha" }))
    plain = FakeTransport.new(accepted)
    client_with(plain).emails.send(from: "app@x.com", to: "a@x.com", subject: "Oi", text: "Oi")

    expect(transport.requests.map { |request| request.headers["x-idempotency-key"] }).to eq(%w[minha minha])
    expect(plain.last.headers).not_to have_key("x-idempotency-key")
  end

  it "RB-DX-05 backoff exponencial com jitter completo e teto" do
    transport = FakeTransport.new(server_error, server_error, server_error, server_error, ok)
    requester_for(transport, CoffeeMail::RetryPolicy.new(max_attempts: 5, base_delay: 1, max_delay: 3))
      .call(operation("GET"))

    expect(sleeps).to eq([0.5, 1.0, 1.5, 1.5])
  end

  it "RB-DX-05 honra Retry-After limitado ao teto" do
    limited = FakeTransport.reply(429, { "error" => { "code" => "RATE_LIMIT_EXCEEDED" } }, "retry-after" => "60")
    short = FakeTransport.reply(429, { "error" => { "code" => "RATE_LIMIT_EXCEEDED" } }, "retry-after" => "2")
    requester_for(FakeTransport.new(limited, short, ok), policy(max_delay: 10)).call(operation("GET"))

    expect(sleeps).to eq([10.0, 2.0])
  end

  it "RB-DX-06 PUT e PATCH não são retentados" do
    put = FakeTransport.new(server_error, ok)
    patch = FakeTransport.new(server_error, ok)
    requester_for(put, policy).call(operation("PUT"))
    requester_for(patch, policy).call(operation("PATCH"))

    expect([put.requests.size, patch.requests.size]).to eq([1, 1])
  end
end
