# frozen_string_literal: true

require "openssl"
require "stringio"
require_relative "../examples/send_email"
require_relative "../examples/error_handling"
require_relative "../examples/webhook_rack"

RSpec.describe "Exemplos executáveis" do
  it "RB-RLS-06 envio de e-mail" do
    transport = FakeTransport.json(202, { "id" => "e1", "status" => "queued" })

    expect(Examples::SendEmail.run(client_with(transport))).to eq("E-mail e1 queued")
    expect(transport.last.headers["x-idempotency-key"]).to eq("boas-vindas-ana")
  end

  it "RB-RLS-06 tratamento de erros por classe" do
    rate_limited = FakeTransport.json(429, { "error" => { "code" => "PLAN_QUOTA_EXCEEDED" } }, "retry-after" => "60")
    not_found = FakeTransport.json(404, { "error" => { "code" => "NOT_FOUND", "message" => "não existe" } })

    expect(Examples::ErrorHandling.run(client_with(rate_limited))).to eq("Aguarde 60s (PLAN_QUOTA_EXCEEDED)")
    expect(Examples::ErrorHandling.run(client_with(not_found))).to start_with("NOT_FOUND")
  end

  it "RB-RLS-06 webhook com Rack" do
    secret = "whsec_exemplo"
    body = '{"event_type":"email.sent","webhook_id":"w1","data":{}}'
    timestamp = Time.now.to_i.to_s
    signature = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.k1.#{body}")}"
    env = { "rack.input" => StringIO.new(body), "HTTP_X_WEBHOOK_SIGNATURE" => signature,
            "HTTP_X_WEBHOOK_TIMESTAMP" => timestamp, "HTTP_X_WEBHOOK_IDEMPOTENCY_KEY" => "k1" }
    events = []
    app = Examples::WebhookApp.new(secret: secret) { |event| events << event.event_type }

    expect(app.call(env).first).to eq(200)
    expect(app.call(env.merge("rack.input" => StringIO.new("#{body} "))).first).to eq(400)
    expect(events).to eq(["email.sent"])
  end
end
