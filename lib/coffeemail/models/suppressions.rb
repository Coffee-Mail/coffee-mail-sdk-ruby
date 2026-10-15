# frozen_string_literal: true

module CoffeeMail
  module Models
    # Detalhe de uma supressão.
    SuppressionDetail = Internal::Model.define(id: :string, email: :string, reason: :string, source: :string,
                                               category: :string, status: :string, expires_at: :time,
                                               created_at: :time)

    # Página de `suppressions.list` (paginação por cursor).
    SuppressionList = Internal::Model.define(suppressions: [SuppressionDetail], next_cursor: :string)

    # Resultado de `suppressions.bulk_create`.
    BulkSuppressionsResult = Internal::Model.define(inserted_count: :integer)
  end
end
