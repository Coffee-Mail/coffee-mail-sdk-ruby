# frozen_string_literal: true

require "uri"

module CoffeeMail
  module Internal
    class Operation < Data.define(:name, :http_method, :path, :query, :body, :headers, :decoder, :full_access,
                                  :idempotent_post, :empty)
      def self.build(name:, http_method:, path:, decoder:, query: {}, body: nil, headers: {}, full_access: false,
                     idempotent_post: false, empty: NO_CONTENT)
        new(name: name, http_method: http_method, path: path, query: query, body: body, headers: headers,
            decoder: decoder, full_access: full_access, idempotent_post: idempotent_post, empty: empty)
      end

      def self.path(template, *params)
        format(template, *params.map { |param| URI.encode_www_form_component(param.to_s) })
      end
    end
  end
end
