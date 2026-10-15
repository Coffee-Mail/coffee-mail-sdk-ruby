# frozen_string_literal: true

RSpec.describe "Modelos e enums" do
  let(:detail) do
    CoffeeMail::Models::EmailDetail.from_wire(
      "id" => "e1", "createdAt" => "2026-10-14T10:00:00Z", "tags" => [{ "name" => "t", "value" => "v" }],
      "campoNovoDaApi" => "ignorado", "status" => "novo_status"
    )
  end

  it "RB-OPS-65 respostas viram Data imutável com Time e campos ausentes em nil" do
    expect(detail).to be_a(Data).and be_frozen
    expect(detail.created_at).to eq(Time.utc(2026, 10, 14, 10))
    expect(detail.subject).to be_nil
    expect(detail.tags.first).to be_a(CoffeeMail::Models::Tag)
    expect { detail.instance_variable_set(:@id, "x") }.to raise_error(FrozenError)
  end

  it "RB-OPS-65 campo desconhecido é ignorado" do
    expect(detail.to_h.keys).not_to include(:campo_novo_da_api)
    expect(CoffeeMail::Models::EmailDetail.members).to include(:open_count, :first_clicked_at)
  end

  it "RB-OPS-65 data inválida vira InvalidResponseError" do
    response = client_with(FakeTransport.json(200, { "id" => "e1", "createdAt" => "ontem" })).emails.get("e1")

    expect(response.error).to be_a(CoffeeMail::InvalidResponseError)
  end

  it "RB-OPS-66 enums abertos: constantes String e valor desconhecido passa" do
    expect(CoffeeMail::EmailStatus::DELIVERED).to eq("delivered")
    expect(CoffeeMail::EmailStatus::ALL).to include("queued", "cancelled")
    expect(CoffeeMail::WebhookStatus::PAUSED).to eq("paused")
    expect(CoffeeMail::DomainStatusReason::DNS_RECORDS_MISSING).to eq("dns_records_missing")
    expect(detail.status).to eq("novo_status")
  end

  it "RB-OPS-66 constantes de enum são congeladas" do
    expect(CoffeeMail::EmailStatus::ALL).to be_frozen
    expect(CoffeeMail::BroadcastStatus::DRAFT).to be_frozen
  end

  it "RB-OPS-67 respostas não documentadas seguem o SDK Java" do
    audiences = CoffeeMail::Models::AudienceList.from_wire("audiences" => [{ "id" => "a1", "totalContacts" => 3 }],
                                                           "total" => 1)
    sent = CoffeeMail::Models::SentBroadcast.from_wire("id" => "b1", "status" => "sending", "recipientsTotal" => 2)
    rotated = CoffeeMail::Models::RotatedSecret.from_wire("webhookId" => "w1", "secret" => "whsec_x")
    key = CoffeeMail::Models::ApiKeyInfo.from_wire("id" => "k1", "organisationId" => "o1", "scopes" => ["full_access"])

    expect(audiences.audiences.first.total_contacts).to eq(3)
    expect(sent.recipients_total).to eq(2)
    expect(rotated.webhook_id).to eq("w1")
    expect(key.scopes).to eq(["full_access"])
  end

  it "RB-OPS-68 list com cursor expõe next_cursor e offset expõe total" do
    cursor = CoffeeMail::Models::SuppressionList.from_wire("suppressions" => [], "nextCursor" => nil)
    offset = CoffeeMail::Models::ContactList.from_wire("contacts" => [{ "id" => "c1" }], "total" => 9)

    expect(cursor.next_cursor).to be_nil
    expect([offset.total, offset.contacts.size]).to eq([9, 1])
  end

  it "RB-OPS-68 modelos sensíveis mascaram segredos em inspect e to_s" do
    webhook = CoffeeMail::Models::WebhookDetail.from_wire("id" => "w1", "secret" => "whsec_abcdef123456")

    expect(webhook.inspect).to include("secret=whsec_****")
    expect(webhook.to_s).not_to include("abcdef123456")
    expect(CoffeeMail::Models::WebhookDetail.new(secret: nil).inspect).to include("secret=nil")
  end
end
