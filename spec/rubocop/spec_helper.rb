# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require_relative "../../rubocop/coffeemail"

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense
end
