# frozen_string_literal: true

module CoffeeMail
  module Models
    # Totais por categoria de envio.
    ChannelStats = Internal::Model.define(sent: :integer, delivered: :integer, bounced: :integer, opened: :integer,
                                          clicked: :integer)

    # Quebra entre transacional e broadcast.
    StatsBreakdown = Internal::Model.define(transactional: ChannelStats, broadcast: ChannelStats)

    # Cliente de e-mail mais usado.
    TopClient = Internal::Model.define(name: :string, count: :integer, percentage: :float, device_type: :string)

    # Ponto da série temporal.
    StatsPoint = Internal::Model.define(
      period: :string, sent: :integer, delivered: :integer, bounced: :integer, failed: :integer, opened: :integer,
      clicked: :integer, transactional: :integer, broadcast: :integer
    )

    # Resultado de `stats.get`.
    Stats = Internal::Model.define(
      total_sent: :integer, total_delivered: :integer, total_bounced: :integer, total_failed: :integer,
      total_opened: :integer, total_clicked: :integer, delivery_rate: :float, open_rate: :float, click_rate: :float,
      breakdown: StatsBreakdown, top_clients: [TopClient], data: [StatsPoint]
    )

    # Resultado de `client.introspect`.
    ApiKeyInfo = Internal::Model.define(id: :string, name: :string, organisation_id: :string, scopes: :strings)
  end
end
