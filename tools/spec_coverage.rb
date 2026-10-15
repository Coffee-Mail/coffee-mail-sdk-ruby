# frozen_string_literal: true

module Tools
  module SpecCoverage
    REQUIREMENT_ROW = /^\| (RB(?:-[A-Z]+)+-\d{2}) \|/
    REQUIREMENT_REFERENCE = /["'](RB(?:-[A-Z]+)+-\d{2})\b/

    Result = Data.define(:requirements, :references) do
      def uncovered = requirements - references.keys
      def unknown = references.keys - requirements
      def complete? = uncovered.empty? && unknown.empty?
    end

    module_function

    def requirements(document)
      document.each_line.filter_map { |line| line[REQUIREMENT_ROW, 1] }.uniq
    end

    def references(sources)
      sources.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(path, content), index|
        content.scan(REQUIREMENT_REFERENCE).flatten.uniq.each { |id| index[id] << path }
      end
    end

    def evaluate(document, sources)
      Result.new(requirements: requirements(document), references: references(sources))
    end
  end
end
