# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe RuboCop::Cop::CoffeeMail::MaxDepth, :config do
  let(:cop_config) { { "Max" => 3 } }

  it "RB-QA-04 aponta profundidade 4 contando blocos" do
    expect_offense(<<~RUBY)
      def call
        items.each do |item|
          if item.ready?
            item.parts.each do |part|
              while part.busy?
              ^^^^^^^^^^^^^^^^ Profundidade 4 excede o máximo de 3. Extraia um método ou use retorno antecipado.
                part.tick
              end
            end
          end
        end
      end
    RUBY
  end

  it "RB-QA-04 aceita profundidade 3 e não conta modificador nem ternário" do
    expect_no_offenses(<<~RUBY)
      def call
        items.each do |item|
          if item.ready?
            item.parts.each do |part|
              part.tick if part.busy?
              part.fast? ? part.run : part.walk
            end
          end
        end
      end
    RUBY
  end

  it "RB-QA-04 aponta só o primeiro nível excedente" do
    expect_offense(<<~RUBY)
      def self.call
        a.each do
          b.each do
            c.each do
              d.each do
              ^^^^^^^^^ Profundidade 4 excede o máximo de 3. Extraia um método ou use retorno antecipado.
                e.each { tick }
              end
            end
          end
        end
      end
    RUBY
  end
end
