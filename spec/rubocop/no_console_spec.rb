# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe RuboCop::Cop::CoffeeMail::NoConsole, :config do
  it "RB-QA-06 aponta puts, warn e streams globais" do
    expect_offense(<<~RUBY)
      puts "oi"
      ^^^^ Saída em console é proibida na biblioteca.
      warn "cuidado"
      ^^^^ Saída em console é proibida na biblioteca.
      $stdout.write("x")
      ^^^^^^^ Saída em console é proibida na biblioteca.
      STDERR.write("x")
      ^^^^^^ Saída em console é proibida na biblioteca.
    RUBY
  end

  it "RB-QA-06 aceita métodos homônimos com receptor" do
    expect_no_offenses(<<~RUBY)
      logger.warn("x")
      io.puts("x")
    RUBY
  end
end
