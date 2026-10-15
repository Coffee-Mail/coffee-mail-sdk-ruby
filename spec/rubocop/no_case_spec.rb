# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe RuboCop::Cop::CoffeeMail::NoCase, :config do
  it "RB-QA-03 aponta case/when" do
    expect_offense(<<~RUBY)
      case status
      ^^^^ case/when e case/in são proibidos. Use um Hash de lookup ou retorno antecipado.
      when 200 then ok
      end
    RUBY
  end

  it "RB-QA-03 aponta case/in" do
    expect_offense(<<~RUBY)
      case payload
      ^^^^ case/when e case/in são proibidos. Use um Hash de lookup ou retorno antecipado.
      in { data: } then data
      end
    RUBY
  end

  it "RB-QA-03 aceita tabela de lookup" do
    expect_no_offenses(<<~RUBY)
      TABLE.fetch(status, Fallback)
    RUBY
  end
end
