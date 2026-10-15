# frozen_string_literal: true

require "openssl"
require "stringio"

RSpec.describe CoffeeMail::Webhook do
  vectors = JSON.parse(File.read(RepoPaths.path("spec/fixtures/webhook_vectors.json"))).fetch("vectors")

  let(:secret) { "whsec_#{"ab12" * 16}" }
  let(:now) { 1_760_000_000 }
  let(:payload) do
    JSON.generate("event_type" => "email.delivered", "webhook_id" => "w1", "data" => { "to" => "a@x.com" })
  end

  def sign(body, timestamp: now, key: "ed4e7012eb856296", with_secret: secret)
    digest = OpenSSL::HMAC.hexdigest("SHA256", with_secret, "#{timestamp}.#{key}.#{body}")
    { "x-webhook-signature" => "sha256=#{digest}", "x-webhook-timestamp" => timestamp.to_s,
      "x-webhook-idempotency-key" => key }
  end

  def verify(body, headers, **options)
    described_class.verify(payload: body, headers: headers, secret: secret, clock: -> { now }, **options)
  end

  it "RB-WHK-01 verifica sem client nem chave de API" do
    expect(verify(payload, sign(payload))).to be(true)
  end

  it "RB-WHK-02 usa timestamp, chave e corpo bruto, nunca o JSON re-serializado" do
    spaced = payload.gsub(":", ": ")

    expect(verify(spaced, sign(spaced))).to be(true)
    expect(verify(payload, sign(spaced))).to be(false)
    expect(verify(payload, sign(payload, key: "outra-chave").merge("x-webhook-idempotency-key" => "ed4e7012eb856296")))
      .to be(false)
  end

  it "RB-WHK-03 rejeita hex maiúsculo e assinatura de tamanho diferente" do
    headers = sign(payload)
    upper = headers.merge("x-webhook-signature" => headers["x-webhook-signature"].sub(/[a-f0-9]+\z/, &:upcase))
    short = headers.merge("x-webhook-signature" => "sha256=abc")

    expect(verify(payload, upper)).to be(false)
    expect(verify(payload, short)).to be(false)
  end

  it "RB-WHK-04 respeita a janela de tolerância com relógio injetável" do
    expect(verify(payload, sign(payload, timestamp: now - 300))).to be(true)
    expect(verify(payload, sign(payload, timestamp: now - 301))).to be(false)
    expect(verify(payload, sign(payload, timestamp: now + 301))).to be(false)
    expect(verify(payload, sign(payload, timestamp: now - 500), tolerance: 600)).to be(true)
    expect(described_class.verify(payload: payload, headers: sign(payload, timestamp: Time.now.to_i), secret: secret))
      .to be(true)
  end

  it "RB-WHK-04 timestamp não numérico ou ausente é inválido" do
    expect(verify(payload, sign(payload).merge("x-webhook-timestamp" => "agora"))).to be(false)
    expect(verify(payload, sign(payload).except("x-webhook-timestamp"))).to be(false)
  end

  it "RB-WHK-05 lê headers sem diferenciar caixa e no formato Rack" do
    signed = sign(payload)
    mixed = signed.transform_keys { |key| key.split("-").map(&:capitalize).join("-") }
    rack = signed.transform_keys { |key| "HTTP_#{key.upcase.tr("-", "_")}" }

    expect(verify(payload, mixed)).to be(true)
    expect(verify(payload, rack)).to be(true)
  end

  it "RB-WHK-06 construct_event devolve o evento ou o motivo da falha" do
    event = described_class.construct_event(payload: payload, headers: sign(payload).merge("x-webhook-test" => "true"),
                                            secret: secret, clock: -> { now })
    bad_signature = described_class.construct_event(payload: "#{payload} ", headers: sign(payload), secret: secret,
                                                    clock: -> { now })
    missing = described_class.construct_event(payload: payload, headers: {}, secret: secret, locale: "en")
    expired = described_class.construct_event(payload: payload, headers: sign(payload, timestamp: 1), secret: secret,
                                              clock: -> { now })

    expect([event.data.event_type, event.data.webhook_id, event.data.data, event.data.test?])
      .to eq(["email.delivered", "w1", { "to" => "a@x.com" }, true])
    expect(bad_signature.error.reason).to eq(:signature)
    expect([missing.error.reason, missing.error.code]).to eq([:missing_header, "WEBHOOK_VERIFICATION_FAILED"])
    expect(missing.error.message).to start_with("Webhook delivery is missing")
    expect(expired.error.reason).to eq(:timestamp)
  end

  it "RB-WHK-06 payload que não é objeto JSON falha com :payload e segredo vazio com :missing_header" do
    body = "[1,2]"
    invalid = described_class.construct_event(payload: body, headers: sign(body), secret: secret, clock: -> { now })
    no_secret = described_class.construct_event(payload: payload, headers: sign(payload), secret: "", clock: -> { now })

    expect(invalid.error).to be_a(CoffeeMail::WebhookVerificationError)
    expect(invalid.error.reason).to eq(:payload)
    expect(no_secret.error.reason).to eq(:missing_header)
  end

  it "RB-WHK-07 from_rack lê o corpo bruto, rebobina e verifica" do
    input = StringIO.new(payload)
    env = { "rack.input" => input }.merge(sign(payload).transform_keys { |key| "HTTP_#{key.upcase.tr("-", "_")}" })
    request = Struct.new(:env).new(env)
    result = described_class.from_rack(request, secret: secret, clock: -> { now })

    expect(result.data.event_type).to eq("email.delivered")
    expect(input.read).to eq(payload)
  end

  it "RB-WHK-07 from_rack sem corpo falha sem exceção" do
    result = described_class.from_rack({}, secret: secret, clock: -> { now })

    expect(result.error.reason).to eq(:missing_header)
  end

  vectors.each do |vector|
    it "RB-WHK-08 vetor compartilhado #{vector["name"]}" do
      headers = { "x-webhook-signature" => vector["signature"], "x-webhook-timestamp" => vector["timestamp"],
                  "x-webhook-idempotency-key" => vector["idempotencyKey"] }
      result = described_class.verify(payload: vector["body"], headers: headers, secret: vector["secret"],
                                      tolerance: vector["toleranceSeconds"], clock: -> { vector["nowEpochSeconds"] })

      expect(result).to eq(vector["expected"])
    end
  end

  it "RB-WHK-08 todos os 11 vetores estão presentes" do
    expect(JSON.parse(File.read(RepoPaths.path("spec/fixtures/webhook_vectors.json"))).fetch("vectors").size).to eq(11)
  end

  it "RB-WHK-09 EventType tem os 16 tipos de webhooks.md §3" do
    expect(described_class::EventType::ALL.size).to eq(16)
    expect(described_class::EventType::EMAIL_DELIVERY_DELAYED).to eq("email.delivery_delayed")
    expect(described_class::EventType::WEBHOOK_TEST).to eq("webhook.test")
    expect(described_class::EventType::BILLING_PLAN_CHANGED).to eq("billing.plan_changed")
  end
end
