# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe RuboCop::Cop::CoffeeMail::NoElse, :config do
  it "RB-QA-03 aponta else em if" do
    expect_offense(<<~RUBY)
      if ready
        go
      else
      ^^^^ else/elsif são proibidos. Use retorno antecipado ou uma tabela de lookup.
        wait
      end
    RUBY
  end

  it "RB-QA-03 aponta elsif" do
    expect_offense(<<~RUBY)
      if ready
        go
      elsif late
      ^^^^^ else/elsif são proibidos. Use retorno antecipado ou uma tabela de lookup.
        run
      end
    RUBY
  end

  it "RB-QA-03 aponta unless com else e rescue com else" do
    expect_offense(<<~RUBY)
      unless ready
        wait
      else
      ^^^^ else/elsif são proibidos. Use retorno antecipado ou uma tabela de lookup.
        go
      end
      begin
        go
      rescue StandardError
        wait
      else
      ^^^^ else/elsif são proibidos. Use retorno antecipado ou uma tabela de lookup.
        done
      end
    RUBY
  end

  it "RB-QA-03 aceita ternário e retorno antecipado" do
    expect_no_offenses(<<~RUBY)
      def call
        return wait unless ready

        late ? run : go
      end
    RUBY
  end
end
