# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Templates de e-mail (`/v1/product/templates`).
    class Templates < Base
      include Internal::Constants

      # @return [Response] com {Models::TemplateDetail}
      def create(name:, html:, alias: nil, subject: nil, preheader: nil, content_json: nil, text_payload: nil,
                 variables: nil, format: nil, source_locale: nil)
        values = { name:, html:, alias: binding.local_variable_get(:alias), subject:, preheader:, content_json:,
                   text_payload:, variables:, format:, source_locale: }
        request("create", Verbs::POST, Routes::TEMPLATES, object(Models::TemplateDetail),
                body: body(values, Internal::Fields::TEMPLATE))
      end

      # @return [Response] com Array de {Models::TemplateDetail}
      def list
        request("list", Verbs::GET, Routes::TEMPLATES, list_of(Models::TemplateDetail, "data"))
      end

      # @param id [String]
      # @return [Response] com {Models::TemplateDetail}
      def get(id)
        request("get", Verbs::GET, route(Routes::TEMPLATE, id), object(Models::TemplateDetail))
      end

      # Atualização parcial: só os campos informados são enviados.
      #
      # @param id [String]
      # @return [Response] com {Models::TemplateDetail}
      def update(id, name: nil, html: nil, alias: nil, subject: nil, preheader: nil, content_json: nil,
                 text_payload: nil, variables: nil, format: nil, source_locale: nil, is_active: nil)
        values = { name:, html:, alias: binding.local_variable_get(:alias), subject:, preheader:, content_json:,
                   text_payload:, variables:, format:, source_locale:, is_active: }
        request("update", Verbs::PATCH, route(Routes::TEMPLATE, id), object(Models::TemplateDetail),
                body: body(values, Internal::Fields::TEMPLATE))
      end

      # @param id [String]
      # @return [Response] com {CoffeeMail::NO_CONTENT}
      def delete(id)
        request("delete", Verbs::DELETE, route(Routes::TEMPLATE, id), raw)
      end

      # Renderiza um HTML com variáveis.
      #
      # @return [Response] com {Models::RenderedTemplate}
      def preview(html:, format: nil, variables: nil)
        request("preview", Verbs::POST, Routes::TEMPLATES_PREVIEW, object(Models::RenderedTemplate),
                body: body({ html:, format:, variables: }, Internal::Fields::TEMPLATE_RENDER))
      end

      # Busca o template e renderiza o HTML dele. Se a busca falhar, devolve essa falha.
      #
      # @param id [String]
      # @param variables [Hash, nil]
      # @return [Response] com {Models::RenderedTemplate}
      def preview_by_id(id, variables: nil)
        found = get(id)
        error = found.error
        return Response.failure(error) if error

        preview(html: found.data.html.to_s, format: found.data.format, variables: variables)
      end

      # Formata (indenta) um HTML.
      #
      # @return [Response] com {Models::FormattedTemplate}
      def format(html:, format: nil)
        request("format", Verbs::POST, Routes::TEMPLATES_FORMAT, object(Models::FormattedTemplate),
                body: body({ html:, format: }, Internal::Fields::TEMPLATE_RENDER))
      end

      # Renderiza com relatório de sanitização.
      #
      # @return [Response] com {Models::TestRenderResult}
      def test_render(html:, format: nil, variables: nil)
        request("test_render", Verbs::POST, Routes::TEMPLATES_TEST_RENDER, object(Models::TestRenderResult),
                body: body({ html:, format:, variables: }, Internal::Fields::TEMPLATE_RENDER))
      end

      # Envia o template para um destinatário de teste.
      #
      # @param id [String]
      # @return [Response] com {Models::TestSendResult}
      def test_send(id, to:, from: nil, subject: nil, variables: nil)
        request("test_send", Verbs::POST, route(Routes::TEMPLATE_TEST_SEND, id), object(Models::TestSendResult),
                body: body({ to:, from:, subject:, variables: }, Internal::Fields::TEMPLATE_TEST_SEND))
      end

      # Lista as versões do template, da mais recente para a mais antiga.
      #
      # @param id [String]
      # @param limit [Integer, nil] de 1 a 100 (padrão da API: 20)
      # @param offset [Integer, nil]
      # @return [Response] com {Models::TemplateVersionList}; template inexistente vira {NotFoundError}
      def list_versions(id, limit: nil, offset: nil)
        request("list_versions", Verbs::GET, route(Routes::TEMPLATE_VERSIONS, id), object(Models::TemplateVersionList),
                query: query({ limit:, offset: }, Internal::Fields::LIST_TEMPLATE_VERSIONS))
      end

      # Busca o conteúdo completo de uma versão.
      #
      # @param id [String]
      # @param version [Integer]
      # @return [Response] com {Models::TemplateVersion}; template ou versão inexistente vira {NotFoundError}
      def get_version(id, version)
        request("get_version", Verbs::GET, route(Routes::TEMPLATE_VERSION, id, version.to_s),
                object(Models::TemplateVersion))
      end

      # Restaura o conteúdo de uma versão no template. A restauração gera uma versão nova.
      #
      # @param id [String]
      # @param version [Integer]
      # @return [Response] com {Models::TemplateDetail}; template ou versão inexistente vira {NotFoundError}
      def restore_version(id, version)
        request("restore_version", Verbs::POST, route(Routes::TEMPLATE_VERSION_RESTORE, id, version.to_s),
                object(Models::TemplateDetail))
      end
    end
  end
end
