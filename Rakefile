# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

desc "Regras da casa (cops CoffeeMail)"
task :standards do
  sh "bundle exec rubocop --only CoffeeMail"
end

desc "Tipos (RBS + Steep strict)"
task :types do
  sh "bundle exec rbs -r json -r net-http -r uri -r openssl -r time -r securerandom -r timeout -I sig validate"
  sh "bundle exec steep check"
end

desc "Gates de versão, rastreabilidade SDD e compatibilidade"
task :gates do
  sh "bin/check-version-sync"
  sh "bin/generate-signatures --check"
  sh "bin/check-spec-coverage"
  sh "bin/check-api-compat"
end

desc "Documentação YARD completa"
task :docs do
  sh "bundle exec yard stats --list-undoc"
end

task default: %i[standards rubocop types spec gates]
