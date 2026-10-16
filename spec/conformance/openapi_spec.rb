# frozen_string_literal: true

require "openapi_first"
require "rack"

RSpec.describe "Conformidade com openapi/product.json" do
  let(:spec_path) { RepoPaths.path("openapi/product.json") }
  let(:document) { JSON.parse(File.read(spec_path)) }
  let(:definition) { OpenapiFirst.load(spec_path) }

  def http_verbs = %w[get post put patch delete]

  def browser_only = ["GET /v1/product/auth/csrf"]

  def body_exempt = ["DELETE /v1/product/domains/{id}"]

  def spec_operations
    document.fetch("paths").flat_map do |path, operations|
      operations.keys.select { |verb| http_verbs.include?(verb) }.map { |verb| "#{verb.upcase} #{path}" }
    end
  end

  def template_for(request)
    path = URI(request.url).path
    spec_operations.find do |operation|
      verb, template = operation.split(" ", 2)
      pattern = Regexp.new("\\A#{template.gsub(/\{[^}]+\}/, "[^/]+")}\\z")
      verb == request.http_method && path.match?(pattern)
    end
  end

  def last_request(status, body)
    transport = FakeTransport.json(status, body)
    yield client_with(transport)
    transport.last
  end

  def captured_requests
    cases = OperationCases::ALL.map { |example| last_request(*example.reply) { |client| example.call.call(client) } }
    introspection = last_request(200, { "id" => "k1" }, &:introspect)
    dated = last_request(200, { "emails" => [] }) do |client|
      client.emails.list(from: Time.utc(2026, 10, 1, 12, 30), to: Time.utc(2026, 10, 2))
    end
    cases + [introspection, dated]
  end

  def rack_request(request)
    env = Rack::MockRequest.env_for(request.url, method: request.http_method, input: request.body.to_s,
                                                 "CONTENT_TYPE" => request.headers["content-type"])
    Rack::Request.new(env)
  end

  it "RB-OPS-63 toda rota do spec tem método no SDK e todo método aponta para rota existente" do
    requests = captured_requests
    mapped = requests.map { |request| template_for(request) }

    expect(mapped).not_to include(nil)
    expect(spec_operations - browser_only - mapped.uniq).to be_empty
    expect(spec_operations.size - browser_only.size).to eq(71)
  end

  it "RB-OPS-64 corpo e query de cada operação são válidos contra o schema" do
    failures = captured_requests.filter_map do |request|
      next if body_exempt.include?(template_for(request))

      validated = definition.validate_request(rack_request(request))
      "#{request.http_method} #{request.url}: #{validated.error.message}" unless validated.valid?
    end

    expect(failures).to be_empty, failures.join("\n")
  end

  it "RB-OPS-64 o validador rejeita campo fora do contrato" do
    request = CoffeeMail::HttpRequest.new(
      http_method: "POST", url: "https://api.coffeemail.com.br/v1/product/domains",
      headers: { "content-type" => "application/json" }, body: '{"name":"x.com","extra":true}', timeout: 1
    )

    expect(definition.validate_request(rack_request(request))).not_to be_valid
  end
end
