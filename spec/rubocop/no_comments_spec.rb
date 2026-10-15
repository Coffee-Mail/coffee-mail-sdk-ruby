# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe RuboCop::Cop::CoffeeMail::NoComments, :config do
  let(:message) do
    "Comentários são proibidos. Só YARD acima de API pública em lib/ e o magic comment frozen_string_literal."
  end

  it "RB-QA-02 aceita magic comment e YARD acima de método público em lib/" do
    expect_no_offenses(<<~RUBY, "/repo/lib/coffeemail/client.rb")
      # frozen_string_literal: true

      module CoffeeMail
        # Cliente da API.
        # @example
        #   CoffeeMail::Client.new
        class Client
          # Envia o e-mail.
          # @return [Response]
          def send_it; end
        end
      end
    RUBY
  end

  it "RB-QA-02 aponta comentário solto e comentário ao fim da linha" do
    expect_offense(<<~RUBY, "/repo/lib/coffeemail/client.rb")
      def call
        # explicação
        ^^^^^^^^^^^^ #{message}
        go # depois
           ^^^^^^^^ #{message}
      end
    RUBY
  end

  it "RB-QA-02 aponta documentação em código interno e em testes" do
    expect_offense(<<~RUBY, "/repo/lib/coffeemail/internal/wire.rb")
      # Interno.
      ^^^^^^^^^^ #{message}
      def parse; end
    RUBY
    expect_offense(<<~RUBY, "/repo/spec/client_spec.rb")
      # Teste.
      ^^^^^^^^ #{message}
      def helper; end
    RUBY
  end

  it "RB-QA-02 aponta diretiva do rubocop" do
    expect_offense(<<~RUBY, "/repo/lib/coffeemail/client.rb")
      go # rubocop:disable Style/Foo
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
    RUBY
  end
end
