# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  add_filter "/spec/"
  add_filter "/tools/"
  add_filter "/rubocop/"
  minimum_coverage line: 85, branch: 78
end

require "coffeemail"
require "json"
require_relative "support/fake_transport"
require_relative "support/operation_cases"
require_relative "support/repo_paths"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
