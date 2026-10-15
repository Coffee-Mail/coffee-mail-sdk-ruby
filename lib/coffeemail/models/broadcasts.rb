# frozen_string_literal: true

module CoffeeMail
  module Models
    # Detalhe de um broadcast.
    BroadcastDetail = Internal::Model.define(
      id: :string, audience_id: :string, audience_name: :string, template_id: :string, subject: :string,
      from_email: :string, reply_to: :string, status: :string, scheduled_at: :time, sent_at: :time,
      cancelled_at: :time, recipients_total: :integer, recipients_queued: :integer, recipients_failed: :integer,
      created_at: :time, updated_at: :time
    )

    # Página de `broadcasts.list` (paginação por cursor).
    BroadcastList = Internal::Model.define(broadcasts: [BroadcastDetail], next_cursor: :string)

    # Resultado de `broadcasts.send`.
    SentBroadcast = Internal::Model.define(id: :string, status: :string, recipients_total: :integer,
                                           recipients_queued: :integer)

    # Resultado de `broadcasts.cancel`.
    CancelledBroadcast = Internal::Model.define(id: :string, status: :string, cancelled_at: :time)
  end
end
