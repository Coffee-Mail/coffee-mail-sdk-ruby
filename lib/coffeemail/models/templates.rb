# frozen_string_literal: true

module CoffeeMail
  module Models
    # Variável declarada em um template.
    TemplateVariable = Internal::Model.define(name: :string, description: :string, type: :string,
                                              fallback_value: :string)

    # Detalhe de um template.
    TemplateDetail = Internal::Model.define(
      id: :string, organisation_id: :string, name: :string, alias: :string, subject: :string,
      preheader: :string, html: :string, content_json: :untyped, text_payload: :string,
      variables: [TemplateVariable], is_active: :boolean, format: :string, source_locale: :string,
      created_at: :time, updated_at: :time
    )

    # Resumo de uma versão de template (`templates.list_versions`). `created_by` é `nil` quando a versão
    # veio de uma API key.
    TemplateVersionSummary = Internal::Model.define(version: :integer, name: :string, subject: :string,
                                                    created_by: :string, created_at: :time)

    # Resultado de `templates.list_versions`: versões da mais recente para a mais antiga e o total.
    TemplateVersionList = Internal::Model.define(data: [TemplateVersionSummary], total: :integer)

    # Conteúdo completo de uma versão de template (`templates.get_version`).
    TemplateVersion = Internal::Model.define(
      version: :integer, name: :string, subject: :string, created_by: :string, created_at: :time,
      template_id: :string, preheader: :string, html: :string, content_json: :untyped, text_payload: :string,
      variables: [TemplateVariable], format: :string, source_locale: :string
    )

    # Resultado de `templates.preview` e `templates.preview_by_id`.
    RenderedTemplate = Internal::Model.define(html: :string, text: :string)

    # Resultado de `templates.format`.
    FormattedTemplate = Internal::Model.define(html: :string)

    # Relatório de sanitização de `templates.test_render`.
    SanitizeReport = Internal::Model.define(scripts: :integer, iframes: :integer, javascript_hrefs: :integer,
                                            event_handlers: :integer)

    # Resultado de `templates.test_render`.
    TestRenderResult = Internal::Model.define(html: :string, text: :string, sanitize_report: SanitizeReport)

    # Resultado de `templates.test_send` e `broadcasts.test_send`.
    TestSendResult = Internal::Model.define(success: :boolean, message_id: :string, recipient: :string)
  end
end
