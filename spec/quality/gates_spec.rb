# frozen_string_literal: true

require "open3"
require "yaml"

RSpec.describe "Gates de qualidade e release" do
  let(:root_dir) { RepoPaths::ROOT }
  let(:sources) { Dir[RepoPaths.path("{lib,spec,tools,rubocop,bin,examples}/**/*")].select { |path| File.file?(path) } }
  let(:ci) { YAML.load_file(RepoPaths.path(".github/workflows/ci.yml")) }
  let(:release) { YAML.load_file(RepoPaths.path(".github/workflows/release.yml")) }
  let(:ci_steps) { ci.dig("jobs", "check", "steps").map { |step| step["run"].to_s }.join("\n") }

  it "RB-QA-01 RuboCop com plugins de performance e RSpec, sem desligar cops em linha" do
    config = YAML.load_file(File.join(root_dir, ".rubocop.yml"))
    directive = %w[rubocop disable].join(":")
    fixtures = [File.join(root_dir, "spec/rubocop/no_comments_spec.rb")]
    inline = (sources - fixtures).select { |path| File.read(path).include?(directive) }

    expect(config["plugins"]).to include("rubocop-performance", "rubocop-rspec")
    expect(inline).to be_empty
  end

  it "RB-QA-07 constantes internas são congeladas" do
    modules = CoffeeMail::Internal::Constants.constants.map { |name| CoffeeMail::Internal::Constants.const_get(name) }
    values = modules.flat_map { |owner| owner.constants.map { |name| owner.const_get(name) } }

    expect(values.reject(&:frozen?)).to be_empty
    expect(CoffeeMail::Internal::Fields::SEND_EMAIL).to be_frozen
  end

  it "RB-QA-08 todo cop próprio tem teste" do
    cops = Dir[File.join(root_dir, "rubocop/cop/coffeemail/*.rb")].map { |path| File.basename(path, ".rb") }
    specs = Dir[File.join(root_dir, "spec/rubocop/*_spec.rb")].map { |path| File.basename(path, "_spec.rb") }

    expect(cops.size).to eq(6)
    expect(cops - specs).to be_empty
  end

  it "RB-QA-09 Steep estrito e toda classe pública com assinatura" do
    signatures = Dir[File.join(root_dir, "sig/**/*.rbs")].map { |path| File.read(path) }
    surface = Tools::ApiCompat.surface(signatures)
    public_names = %w[CoffeeMail::Client CoffeeMail::Response CoffeeMail::Error CoffeeMail::RetryPolicy
                      CoffeeMail::Webhook CoffeeMail::Webhook::Event CoffeeMail::Resources::Emails
                      CoffeeMail::Models::EmailDetail CoffeeMail::EmailStatus CoffeeMail::HttpRequest]

    expect(File.read(File.join(root_dir, "Steepfile"))).to include("D::Ruby.strict")
    expect(public_names - surface.keys).to be_empty
    expect(ci_steps).to include("steep check").and include("rbs").and include("generate-signatures --check")
  end

  it "RB-QA-10 cobertura mínima de 85% de linhas e 78% de branches" do
    helper = File.read(File.join(root_dir, "spec/spec_helper.rb"))

    expect(helper).to include("minimum_coverage line: 85, branch: 78").and include("enable_coverage :branch")
  end

  it "RB-QA-14 auditoria de dependências no CI" do
    audit = ci.dig("jobs", "vulnerabilities", "steps").map { |step| step["run"].to_s }

    expect(audit).to include("bundle exec bundler-audit check --update")
  end

  it "RB-QA-15 matriz 3.3, 3.4 e estável na ordem dos gates" do
    order = ["check-version-sync", "rubocop --only CoffeeMail", "bundle exec rubocop\n", "steep check", "rspec",
             "check-spec-coverage", "check-api-compat", "smoke-test"]
    positions = order.map { |marker| ci_steps.index(marker) }

    expect(ci.dig("jobs", "check", "strategy", "matrix", "ruby")).to eq(%w[3.3 3.4 ruby])
    expect(positions).to all(be_a(Integer))
    expect(positions).to eq(positions.sort)
  end

  it "RB-QA-16 nenhum arquivo cita repositório privado" do
    pattern = /coffee-mail-(?:a)pi|coffee-mail-(?:w)eb/
    files = Dir[File.join(root_dir, "**/*"), File.join(root_dir, ".github/**/*")]
            .reject { |path| path.include?("/vendor/") || path.include?("/coverage/") || File.directory?(path) }
    offenders = files.select { |path| File.read(path, encoding: "UTF-8").scrub.match?(pattern) }

    expect(offenders).to be_empty
  end

  it "RB-RLS-02 gemspec sem dependências de runtime e com metadados obrigatórios" do
    spec = Gem::Specification.load(File.join(root_dir, "coffeemail.gemspec"))

    expect(spec.runtime_dependencies).to be_empty
    expect(spec.required_ruby_version.to_s).to eq(">= 3.3")
    expect(spec.metadata).to include("rubygems_mfa_required" => "true")
    expect(spec.metadata.keys).to include("source_code_uri", "changelog_uri")
    expect(spec.files.map do |path|
      path.split("/").first
    end.uniq).to match_array(%w[lib sig README.md LICENSE CHANGELOG.md])
  end

  it "RB-RLS-03 smoke test instala o pacote gerado e envia com transporte falso" do
    output, status = Open3.capture2e("bin/smoke-test", chdir: root_dir)

    expect(status).to be_success, output
    expect(output).to include("smoke ok: e1")
  end

  it "RB-RLS-04 README segue o roteiro único e documenta as peculiaridades" do
    readme = File.read(File.join(root_dir, "README.md"))
    sections = ["Visão geral", "Status do projeto", "Requisitos", "Instalação", "Início rápido", "Configuração",
                "Tratamento de erros", "Referência", "Webhooks", "Versionamento e releases", "Testes e qualidade",
                "Estrutura do repositório", "Contribuição", "Projetos relacionados", "Licença"]

    expect(sections.reject { |section| readme.match?(/^## .*#{Regexp.escape(section)}/) }).to be_empty
    expect(readme).to include("Deduplicação implícita").and include("não traz o id do e-mail")
    expect(readme).to include("muda a cada tentativa")
  end

  it "RB-RLS-05 toda a API pública tem documentação YARD" do
    output, status = Open3.capture2e(RbConfig.ruby, Gem.bin_path("yard", "yard"), "stats", "--list-undoc",
                                     chdir: root_dir)

    expect(status).to be_success, output
    expect(output).to include("100.00% documented")
  end

  it "RB-RLS-07 arquivos de comunidade presentes" do
    files = %w[LICENSE CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md CHANGELOG.md AGENTS.md
               .github/pull_request_template.md .github/ISSUE_TEMPLATE/bug_report.yml
               .github/ISSUE_TEMPLATE/feature_request.yml]

    expect(files.reject { |file| File.exist?(File.join(root_dir, file)) }).to be_empty
    expect(File.read(File.join(root_dir,
                               "CHANGELOG.md"))).to include("Keep a Changelog").and include("## [Não lançado]")
  end

  it "RB-RLS-08 release por tag com verificação de versão e trusted publishing" do
    steps = release.dig("jobs", "release", "steps")
    runs = steps.map { |step| step["run"].to_s }.join("\n")

    expect(release.dig(true, "push", "tags") || release.dig("on", "push", "tags")).to eq(["v*"])
    expect(release.fetch("permissions")).to include("id-token" => "write")
    expect(runs).to include('bin/check-version-sync --tag "$GITHUB_REF_NAME"')
    expect(steps.map { |step| step["uses"] }).to include("rubygems/release-gem@v1")
  end
end
