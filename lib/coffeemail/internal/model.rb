# frozen_string_literal: true

require "time"

module CoffeeMail
  module Internal
    module OptionalMembers
      def initialize(**attributes)
        super(**self.class.const_get(:DEFAULTS), **attributes)
      end
    end

    module Model
      SCALAR_READERS = {
        string: :to_s.to_proc,
        integer: ->(value) { Integer(value) },
        float: ->(value) { Float(value) },
        boolean: ->(value) { value == true },
        time: ->(value) { Time.iso8601(value) },
        hash: :to_h.to_proc,
        strings: ->(value) { value.map(&:to_s) },
        untyped: ->(value) { value },
      }.freeze
      MASKED_SUFFIX = "****"
      MASK_VISIBLE_CHARS = 6

      RAW = ->(value) { value }

      module_function

      def define(masked: [], **fields, &)
        klass = Data.define(*fields.keys, &)
        klass.const_set(:FIELDS, fields.freeze)
        install_defaults(klass, fields)
        install_from_wire(klass, fields)
        mask(klass, masked) unless masked.empty?
        klass
      end

      def install_defaults(klass, fields)
        klass.const_set(:DEFAULTS, fields.keys.to_h { |member| [member, nil] }.freeze)
        klass.prepend(OptionalMembers)
      end

      def install_from_wire(klass, fields)
        readers = fields.to_h { |member, kind| [member, reader(wire_key(member), kind)] }
        klass.define_singleton_method(:from_wire) do |hash|
          klass.new(**readers.transform_values { |read| read.call(hash) })
        end
      end

      def reader(key, kind)
        convert = converter(kind)
        ->(hash) { hash.fetch(key, nil).then { |value| value.nil? ? nil : convert.call(value) } }
      end

      def converter(kind)
        return ->(value) { value.map { |entry| kind.first.from_wire(entry) } } if kind.is_a?(Array)
        return ->(value) { kind.from_wire(value) } if kind.respond_to?(:from_wire)

        SCALAR_READERS.fetch(kind)
      end

      def wire_key(member)
        head, *rest = member.to_s.split("_")
        [head, *rest.map(&:capitalize)].join
      end

      def mask(klass, masked)
        klass.define_method(:inspect) { Model.masked_inspect(self, masked) }
        klass.alias_method(:to_s, :inspect)
      end

      def masked_inspect(instance, masked)
        values = instance.to_h.map do |name, value|
          "#{name}=#{masked.include?(name) ? masked(value) : value.inspect}"
        end
        "#<data #{instance.class.name} #{values.join(", ")}>"
      end

      def masked(value)
        value.nil? ? "nil" : "#{value.to_s[0, MASK_VISIBLE_CHARS]}#{MASKED_SUFFIX}"
      end

      def object(model)
        ->(value) { model.from_wire(value) }
      end

      def list(model, key = nil)
        ->(value) { (key.nil? ? value : value.fetch(key)).map { |entry| model.from_wire(entry) } }
      end
    end
  end
end
