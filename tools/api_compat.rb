# frozen_string_literal: true

require "rbs"

module Tools
  module ApiCompat
    INTERNAL_NAMESPACE = /(?:\A|::)Internal(?:::|\z)/

    Signature = Data.define(:required_positionals, :max_positionals, :required_keywords, :keywords, :rest_keywords)
    UNTYPED = Signature.new(required_positionals: 0, max_positionals: Float::INFINITY,
                            required_keywords: [], keywords: [], rest_keywords: true)

    module_function

    def surface(sources)
      sources.each_with_object({}) do |source, index|
        _, _, declarations = RBS::Parser.parse_signature(source)
        declarations.each { |declaration| collect(declaration, "", index) }
      end
    end

    def breaking_changes(old_sources, new_sources)
      old_surface = surface(old_sources)
      new_surface = surface(new_sources)
      old_surface.flat_map { |name, signature| compare(name, signature, new_surface) }
    end

    def compare(name, old_signature, new_surface)
      return ["#{name} removido"] unless new_surface.key?(name)
      return [] if old_signature == :entity

      method_changes(name, old_signature, new_surface.fetch(name))
    end

    def method_changes(name, old_sig, new_sig)
      [
        ("#{name}: exige mais argumentos posicionais" if new_sig.required_positionals > old_sig.required_positionals),
        ("#{name}: aceita menos argumentos posicionais" if new_sig.max_positionals < old_sig.max_positionals),
        *removed_keywords(name, old_sig, new_sig),
        *(new_sig.required_keywords - old_sig.required_keywords).map do |key|
          "#{name}: kwarg #{key} virou obrigatório"
        end,
      ].compact
    end

    def removed_keywords(name, old_sig, new_sig)
      return [] if new_sig.rest_keywords

      (old_sig.keywords - new_sig.keywords).map { |key| "#{name}: kwarg #{key} removido" }
    end

    def collect(declaration, namespace, index)
      return collect_constant(declaration, namespace, index) if declaration.is_a?(RBS::AST::Declarations::Constant)
      return unless declaration.respond_to?(:members)

      name = "#{namespace}#{declaration.name.to_s.delete_prefix("::")}"
      return if name.match?(INTERNAL_NAMESPACE)

      index[name] = :entity
      collect_members(declaration.members, name, index)
    end

    def collect_constant(declaration, namespace, index)
      name = "#{namespace}#{declaration.name}"
      index[name] = :entity unless name.match?(INTERNAL_NAMESPACE)
    end

    def collect_members(members, owner, index)
      visibility = :public
      members.each do |member|
        visibility = :private if member.is_a?(RBS::AST::Members::Private)
        visibility = :public if member.is_a?(RBS::AST::Members::Public)
        collect_member(member, owner, index, visibility)
      end
    end

    def collect_member(member, owner, index, visibility)
      return collect(member, "#{owner}::", index) if member.is_a?(RBS::AST::Declarations::Base)
      return collect_attribute(member, owner, index) if member.is_a?(RBS::AST::Members::AttrReader)
      return unless member.is_a?(RBS::AST::Members::MethodDefinition)
      return if (member.visibility || visibility) == :private

      index["#{owner}#{member.kind == :singleton ? "." : "#"}#{member.name}"] = signature(member)
    end

    def collect_attribute(member, owner, index)
      index["#{owner}##{member.name}"] =
        signature_of(RBS::Types::Function.empty(RBS::Types::Bases::Any.new(location: nil)))
    end

    def signature(member)
      function = member.overloads.first&.method_type&.type
      return UNTYPED unless function.is_a?(RBS::Types::Function)

      signature_of(function)
    end

    def signature_of(function)
      Signature.new(
        required_positionals: function.required_positionals.size + function.trailing_positionals.size,
        max_positionals: function.rest_positionals ? Float::INFINITY : positional_count(function),
        **keyword_shape(function),
      )
    end

    def keyword_shape(function)
      required = function.required_keywords.keys
      {
        required_keywords: required.sort,
        keywords: (required + function.optional_keywords.keys).sort,
        rest_keywords: !function.rest_keywords.nil?,
      }
    end

    def positional_count(function)
      function.required_positionals.size + function.optional_positionals.size + function.trailing_positionals.size
    end
  end
end
