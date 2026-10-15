# frozen_string_literal: true

RSpec.describe "Paginação automática" do
  def page(key, items, cursor)
    FakeTransport.reply(200, { key => items, "nextCursor" => cursor })
  end

  it "RB-DX-07 pages percorre o cursor até o fim, de forma preguiçosa" do
    transport = FakeTransport.new(page("emails", [{ "id" => "1" }], "c2"), page("emails", [{ "id" => "2" }], nil))
    pages = client_with(transport).emails.pages(limit: 1)

    expect(transport.requests).to be_empty
    expect(pages.flat_map { |response| response.data.emails.map(&:id) }.to_a).to eq(%w[1 2])
    expect(transport.requests.map { |request| URI.decode_www_form(URI(request.url).query).to_h["after"] })
      .to eq([nil, "c2"])
  end

  it "RB-DX-07 para na primeira falha e a entrega" do
    failure = FakeTransport.reply(500, "")
    transport = FakeTransport.new(page("suppressions", [], "c2"), failure, page("suppressions", [], nil))
    responses = client_with(transport).suppressions.pages.to_a

    expect(responses.map(&:success?)).to eq([true, false])
    expect(transport.requests.size).to eq(2)
  end

  it "RB-DX-07 cursor também em broadcasts" do
    transport = FakeTransport.new(page("broadcasts", [{ "id" => "b1" }], nil))

    expect(client_with(transport).broadcasts.pages(status: "sent").to_a.size).to eq(1)
  end

  it "RB-DX-07 offset avança pelo tamanho da página até o total" do
    first = FakeTransport.reply(200, { "contacts" => [{ "id" => "1" }, { "id" => "2" }], "total" => 3 })
    last = FakeTransport.reply(200, { "contacts" => [{ "id" => "3" }], "total" => 3 })
    transport = FakeTransport.new(first, last)
    ids = client_with(transport).audiences.contacts.pages("a1", limit: 2).flat_map do |response|
      response.data.contacts.map(&:id)
    end

    expect(ids.to_a).to eq(%w[1 2 3])
    expect(transport.requests.map { |request| URI.decode_www_form(URI(request.url).query).to_h["offset"] })
      .to eq(%w[0 2])
  end

  it "RB-DX-07 offset para em página vazia e em falha" do
    empty = FakeTransport.new(FakeTransport.reply(200, { "audiences" => [], "total" => 10 }))
    failing = FakeTransport.new(FakeTransport.reply(401, ""))

    expect(client_with(empty).audiences.pages.to_a.size).to eq(1)
    expect(client_with(failing).audiences.pages.to_a.map(&:failure?)).to eq([true])
  end
end
