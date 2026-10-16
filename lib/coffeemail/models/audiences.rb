# frozen_string_literal: true

module CoffeeMail
  module Models
    # Detalhe de uma audiência.
    AudienceDetail = Internal::Model.define(
      id: :string, name: :string, description: :string, active: :boolean, total_contacts: :integer,
      contacts_count: :integer, created_at: :time, updated_at: :time
    )

    # Página de `audiences.list` (paginação por offset).
    AudienceList = Internal::Model.define(audiences: [AudienceDetail], total: :integer)

    # Resultado de `audiences.update` e `audiences.contacts.update`.
    UpdatedResource = Internal::Model.define(id: :string)

    # Contato de uma audiência.
    Contact = Internal::Model.define(id: :string, email: :string, first_name: :string, last_name: :string,
                                     metadata: :hash, subscribed: :boolean, created_at: :time)

    # Página de `audiences.contacts.list` (paginação por offset).
    ContactList = Internal::Model.define(contacts: [Contact], total: :integer)

    # Contato rejeitado em `audiences.contacts.bulk_add`.
    BulkContactError = Internal::Model.define(email: :string, reason: :string)

    # Resultado de `audiences.contacts.bulk_add`.
    BulkAddContactsResult = Internal::Model.define(inserted: :integer, skipped: :integer, errors: [BulkContactError])
  end
end
