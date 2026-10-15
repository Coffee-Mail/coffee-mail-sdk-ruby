# frozen_string_literal: true

require_relative "support/local_http_server"

RSpec.describe "Transporte e headers" do
  let(:transport) do
    FakeTransport.json(202, { "id" => "e1", "status" => "queued", "queuedAt" => "2026-10-14T10:00:00Z" })
  end
  let(:client) { client_with(transport) }

  def send_email(**extra)
    client.emails.send(from: "app@exemplo.com", to: "ana@exemplo.com", subject: "Oi", text: "Oi", **extra)
  end

  it "RB-TRN-01 usa a URL fixa da API com o prefixo /v1/product" do
    client.emails.get("e1")

    expect(transport.last.url).to eq("https://api.coffeemail.com.br/v1/product/emails/e1")
  end

  it "RB-TRN-02 envia autorização, accept, idioma e User-Agent" do
    client_with(transport, locale: "en").emails.get("e1")

    expect(transport.last.headers).to include(
      "authorization" => "Bearer #{API_KEY}",
      "accept" => "application/json",
      "accept-language" => "en",
      "user-agent" => "coffeemail-ruby/#{CoffeeMail::VERSION}",
    )
  end

  it "RB-TRN-03 Content-Type só quando há corpo" do
    client.emails.get("e1")
    without_body = transport.last
    send_email

    expect(without_body.headers).not_to have_key("content-type")
    expect(without_body.body).to be_nil
    expect(transport.last.headers["content-type"]).to eq("application/json")
  end

  it "RB-TRN-04 idempotency_key e sandbox viram headers e saem do corpo" do
    send_email(idempotency_key: "chave-1", sandbox: true)

    expect(transport.last.headers).to include("x-idempotency-key" => "chave-1", "x-coffeemail-sandbox" => "true")
    expect(transport.last_body.keys).not_to include("idempotencyKey", "idempotency_key", "sandbox")
  end

  it "RB-TRN-04 sem sandbox nem chave não envia esses headers" do
    send_email

    expect(transport.last.headers.keys).not_to include("x-idempotency-key", "x-coffeemail-sandbox")
  end

  it "RB-TRN-05 batch une os headers dos itens e limpa os corpos" do
    batch = FakeTransport.json(202, [{ "ok" => true, "data" => { "id" => "e1" } }])
    items = [
      { from: "app@exemplo.com", to: "a@exemplo.com", subject: "1", text: "1", idempotency_key: "lote-1" },
      { from: "app@exemplo.com", to: "b@exemplo.com", subject: "2", text: "2", sandbox: true },
    ]
    client_with(batch).emails.send_batch(items)

    expect(batch.last.headers).to include("x-idempotency-key" => "lote-1", "x-coffeemail-sandbox" => "true")
    expect(batch.last_body.flat_map(&:keys)).not_to include("idempotency_key", "sandbox")
  end

  it "RB-TRN-06 propaga x-request-id dentro de with_request_id, inclusive em threads filhas" do
    CoffeeMail.with_request_id("req-abc") do
      client.emails.get("e1")
      Thread.new { client.emails.get("e2") }.join
    end

    expect(transport.requests.map { |request| request.headers["x-request-id"] }).to eq(%w[req-abc req-abc])
  end

  it "RB-TRN-06 fora do bloco não envia x-request-id e restaura o valor anterior" do
    CoffeeMail.with_request_id("externo") { CoffeeMail.with_request_id("interno") { nil } }
    outside = CoffeeMail.current_request_id
    client.emails.get("e1")

    expect(outside).to be_nil
    expect(transport.last.headers).not_to have_key("x-request-id")
  end

  it "RB-TRN-07 aceita qualquer objeto com call(request)" do
    seen = []
    lambda_transport = lambda do |request|
      seen << request
      FakeTransport.reply(200, { "tags" => [] })
    end
    response = client_with(lambda_transport).emails.get_tags

    expect(response).to be_success
    expect(seen.first).to be_a(CoffeeMail::HttpRequest)
    expect(seen.first.http_method).to eq("GET")
  end

  it "RB-TRN-07 HttpRequest#inspect não mostra o header de autorização" do
    client.emails.get("e1")

    expect(transport.last.inspect).not_to include(API_KEY)
    expect(transport.last.to_s).to include("GET https://api.coffeemail.com.br/v1/product/emails/e1")
  end

  describe "transporte padrão (Net::HTTP)" do
    let(:net_transport) { CoffeeMail::Internal::NetHttpTransport.new }

    def request_to(url, timeout: 2, body: nil, method: "POST")
      CoffeeMail::HttpRequest.new(http_method: method, url: url, headers: { "x-test" => "1" }, body: body,
                                  timeout: timeout)
    end

    it "RB-TRN-08 envia método, headers e corpo e devolve headers minúsculos" do
      server = LocalHttpServer.new
      response = net_transport.call(request_to(server.url("/v1/product/emails"), body: '{"a":1}'))
      received = server.received.pop

      expect(received[:head]).to start_with("POST /v1/product/emails HTTP/1.1")
      expect(received[:head]).to match(/x-test: 1/i)
      expect(received[:body]).to eq('{"a":1}')
      expect(response.status).to eq(200)
      expect(response.header("X-Request-Id")).to eq("req-1")
    ensure
      server&.close
    end

    it "RB-TRN-09 timeout vira NetworkError com REQUEST_TIMEOUT" do
      server = LocalHttpServer.new(delay: 2)
      result = CoffeeMail::Internal::TransportGuard.call(net_transport, request_to(server.url, timeout: 0.2,
                                                                                               method: "GET"), "pt-BR")

      expect(result).to be_a(CoffeeMail::NetworkError)
      expect(result.status).to eq(0)
      expect(result.code).to eq("NETWORK_ERROR")
      expect(result.message).to eq("A requisição excedeu o tempo limite configurado de 200ms.")
      expect(result.cause).to be_a(Timeout::Error)
    ensure
      server&.close
    end

    it "RB-TRN-10 conexão recusada vira NetworkError com a causa original" do
      port = TCPServer.new("127.0.0.1", 0).then { |socket| socket.addr[1].tap { socket.close } }
      result = CoffeeMail::Internal::TransportGuard.call(net_transport, request_to("http://127.0.0.1:#{port}/"), "en")

      expect(result).to be_a(CoffeeMail::NetworkError)
      expect(result.message).to start_with("Network error while attempting to communicate with CoffeeMail API:")
      expect(result.cause).to be_a(SystemCallError)
    end
  end

  it "RB-TRN-10 exceção de transporte injetado vira NetworkError no envelope" do
    response = client_with(FakeTransport.new(SocketError.new("getaddrinfo falhou"))).emails.get("e1")

    expect(response).to be_failure
    expect(response.error).to be_a(CoffeeMail::NetworkError)
    expect(response.error.message).to include("getaddrinfo falhou")
    expect(response.status).to eq(0)
  end

  it "RB-TRN-11 204 e 2xx vazio são sucesso com NO_CONTENT" do
    empty = FakeTransport.new(FakeTransport.reply(204, ""), FakeTransport.reply(200, "  "))
    no_content_client = client_with(empty)

    expect(no_content_client.emails.cancel("e1").data).to be(CoffeeMail::NO_CONTENT)
    expect(no_content_client.templates.delete("t1").data).to be(CoffeeMail::NO_CONTENT)
    expect(CoffeeMail::NO_CONTENT.inspect).to eq("CoffeeMail::NO_CONTENT")
  end

  it "RB-TRN-12 2xx com corpo inválido vira InvalidResponseError" do
    response = client_with(FakeTransport.json(200, "<html>", "x-request-id" => "req-9")).emails.get("e1")

    expect(response.error).to be_a(CoffeeMail::InvalidResponseError)
    expect(response.error.code).to eq("INVALID_RESPONSE")
    expect(response.error.message).to eq("A resposta do servidor não pôde ser interpretada como JSON válido.")
    expect(response.error.request_id).to eq("req-9")
  end

  it "RB-TRN-12 2xx com JSON de formato inesperado também vira InvalidResponseError" do
    response = client_with(FakeTransport.json(200, [1, 2])).emails.get("e1")

    expect(response.error).to be_a(CoffeeMail::InvalidResponseError)
  end

  it "RB-TRN-13 escapa parâmetros de path e serializa a query" do
    list = FakeTransport.json(200, { "emails" => [], "nextCursor" => nil })
    client_with(list).emails.get("a/b c")
    escaped = list.last.url
    client_with(list).emails.list(from: Time.utc(2026, 10, 1), status: nil, limit: 5)

    expect(escaped).to end_with("/emails/a%2Fb+c")
    expect(list.last_query).to eq("from" => "2026-10-01T00:00:00.000Z", "limit" => "5")
  end
end
