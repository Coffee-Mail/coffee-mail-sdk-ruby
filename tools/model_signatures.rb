# frozen_string_literal: true

module Tools
  module ModelSignatures
    SCALAR_TYPES = {
      string: "String", integer: "Integer", float: "Float", boolean: "bool", time: "Time",
      hash: "Hash[String, untyped]", strings: "Array[String]", untyped: "untyped"
    }.freeze
    HEADER = "# Gerado por bin/generate-signatures a partir de lib/coffeemail/models e enums. Não edite.\n"

    module_function

    def render(models, enums)
      body = [*enums.map { |owner| enum(owner) }, *models.map { |model| model(model) }].join("\n")
      "#{HEADER}module CoffeeMail\n  module Models\n  end\nend\n\n#{body}"
    end

    def enum(owner)
      constants = owner::ALL.map { |value| "  #{CoffeeMail::Internal::Enum.constant_name(value)}: String\n" }.join
      "module #{owner.name}\n#{constants}  ALL: Array[String]\nend\n"
    end

    def model(klass)
      fields = klass::FIELDS
      readers = fields.map { |member, kind| "  attr_reader #{member}: #{type(kind)}?\n" }.join
      keywords = fields.map { |member, kind| "?#{member}: #{type(kind)}?" }.join(", ")
      <<~RBS
        class #{klass.name} < Data
          FIELDS: Hash[Symbol, untyped]
        #{readers.chomp}
          def self.new: (#{keywords}) -> instance
          def self.from_wire: (Hash[String, untyped] hash) -> #{klass.name}
        end
      RBS
    end

    def type(kind)
      return "Array[#{kind.first.name}]" if kind.is_a?(Array)
      return kind.name if kind.is_a?(Class)

      SCALAR_TYPES.fetch(kind)
    end
  end
end
