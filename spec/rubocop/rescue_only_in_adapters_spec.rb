# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe RuboCop::Cop::CoffeeMail::RescueOnlyInAdapters, :config do
  let(:cop_config) { { "AllowedFiles" => ["lib/coffeemail/internal/wire.rb"] } }

  it "RB-QA-05 aponta rescue e raise fora dos adaptadores" do
    expect_offense(<<~RUBY, "/repo/lib/coffeemail/resources/emails.rb")
      def call
        raise ArgumentError, "x"
        ^^^^^ rescue/raise só nos adaptadores isolados (AllowedFiles). Devolva o erro no envelope.
      rescue StandardError
      ^^^^^^ rescue/raise só nos adaptadores isolados (AllowedFiles). Devolva o erro no envelope.
        nil
      end
    RUBY
  end

  it "RB-QA-05 aceita rescue no adaptador isolado" do
    expect_no_offenses(<<~RUBY, "/repo/lib/coffeemail/internal/wire.rb")
      def parse(body)
        JSON.parse(body)
      rescue JSON::ParserError
        nil
      end
    RUBY
  end

  it "RB-QA-05 aceita raise com receptor explícito" do
    expect_no_offenses(<<~RUBY, "/repo/lib/coffeemail/resources/emails.rb")
      promise.raise
    RUBY
  end
end
