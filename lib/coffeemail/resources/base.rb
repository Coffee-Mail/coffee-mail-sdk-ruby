# frozen_string_literal: true

module CoffeeMail
  # Recursos da API. São expostos pelo {Client}; não instancie diretamente.
  module Resources
    # Base comum dos recursos: declara operações e delega ao requester interno.
    class Base
      # @api private
      def initialize(requester)
        @requester = requester
        freeze
      end

      # @return [String]
      def inspect = "#<#{self.class.name}>"

      private

      def resource_name = self.class.name.split("::").last.downcase

      def request(name, http_method, path, decoder, **options)
        @requester.call(Internal::Operation.build(name: "#{resource_name}.#{name}", http_method: http_method,
                                                  path: path, decoder: decoder, **options))
      end

      def route(template, *params) = Internal::Operation.path(template, *params)

      def body(values, table) = Internal::Encoder.body(values, table)

      def query(values, table) = Internal::Encoder.query(values, table)

      def object(model) = Internal::Model.object(model)

      def optional(model) = Internal::Model.optional(model)

      def list_of(model, key = nil) = Internal::Model.list(model, key)

      def raw = Internal::Model::RAW
    end
  end
end
