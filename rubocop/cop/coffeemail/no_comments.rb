# frozen_string_literal: true

module RuboCop
  module Cop
    module CoffeeMail
      class NoComments < Base
        MSG = "Comentários são proibidos. Só YARD acima de API pública em lib/ e o magic comment frozen_string_literal."
        MAGIC_COMMENT = /\A#\s*frozen_string_literal:\s*true\z/
        SHEBANG = /\A#!/
        DOCUMENTABLE = /\A(?:def\s|class\s|module\s|[A-Z][A-Za-z0-9_]*\s*=|attr_reader\s|alias_method\s|Data\.define)/

        def on_new_investigation
          lines = processed_source.lines
          blocks = comment_blocks
          blocks.each { |block| inspect_block(block, lines) }
        end

        private

        def comment_blocks
          processed_source.comments.slice_when { |prev, curr| curr.loc.line != prev.loc.line + 1 }.to_a
        end

        def inspect_block(block, lines)
          return if allowed_block?(block, lines)

          block.reject { |comment| exempt?(comment) }.each { |comment| add_offense(comment) }
        end

        def allowed_block?(block, lines)
          return false unless documentation_scope?
          return false unless block.all? { |comment| own_line?(comment, lines) }

          next_code = lines.drop(block.last.loc.line).find { |line| !line.strip.empty? }
          next_code.to_s.strip.match?(DOCUMENTABLE)
        end

        def exempt?(comment)
          return true if comment.loc.line == 1 && comment.text.match?(SHEBANG)

          comment.loc.line <= 2 && comment.text.match?(MAGIC_COMMENT)
        end

        def own_line?(comment, lines)
          lines[comment.loc.line - 1].strip.start_with?("#")
        end

        def documentation_scope?
          path = processed_source.file_path.to_s
          path.include?("/lib/") && !path.include?("/internal/")
        end
      end
    end
  end
end
