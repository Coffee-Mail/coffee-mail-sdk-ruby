# frozen_string_literal: true

require "open3"
require "tmpdir"
require_relative "../../tools/spec_coverage"
require_relative "../../tools/version_sync"
require_relative "../../tools/api_compat"

RSpec.describe "Gates de rastreabilidade, versão e compatibilidade" do
  describe Tools::SpecCoverage do
    let(:document) { "| RB-CLI-01 | [M] | a |\n| RB-CLI-02 | [M] | b |\ntexto RB-CLI-99 fora de tabela\n" }

    it "RB-QA-12 completo quando todo requisito tem teste" do
      result = described_class.evaluate(document, "a_spec.rb" => 'it "RB-CLI-01 x"; it "RB-CLI-02 y"')

      expect(result).to be_complete
      expect(result.requirements).to eq(%w[RB-CLI-01 RB-CLI-02])
    end

    it "RB-QA-12 aponta requisito sem teste e teste com ID inexistente" do
      unknown_id = "RB-ERR-#{70 + 7}"
      result = described_class.evaluate(document, "a_spec.rb" => %(it "RB-CLI-01 x"; it "#{unknown_id} z"))

      expect(result).not_to be_complete
      expect(result.uncovered).to eq(["RB-CLI-02"])
      expect(result.unknown).to eq([unknown_id])
    end

    it "RB-QA-12 o SPEC real está completamente coberto" do
      output, status = Open3.capture2e("bin/check-spec-coverage", chdir: RepoPaths::ROOT)

      expect(status).to be_success, output
    end
  end

  describe Tools::VersionSync do
    let(:headers) { "USER_AGENT_VALUE = \"coffeemail-ruby/\#{CoffeeMail::VERSION}\"" }
    let(:changelog) { "## [Não lançado]\n\n## [0.1.0] - 2026-10-14\n" }

    def problems(**overrides)
      described_class.problems(version: "0.1.0", gemspec_version: "0.1.0", headers_source: headers,
                               changelog: changelog, **overrides)
    end

    it "RB-RLS-01 versão, gemspec, User-Agent, CHANGELOG e tag sincronizados" do
      expect(problems(tag: "v0.1.0")).to be_empty
    end

    it "RB-RLS-01 detecta cada dessincronia" do
      expect(problems(gemspec_version: "0.2.0").first).to include("gemspec declara 0.2.0")
      expect(problems(headers_source: 'USER_AGENT_VALUE = "coffeemail-ruby/0.1.0"').first).to include("User-Agent")
      expect(problems(changelog: "## [0.3.0] - 2026-12-01\n").first).to include("mais nova")
      expect(problems(tag: "v0.2.0").first).to include("não corresponde")
      expect(problems(changelog: "## [Não lançado]\n", tag: "v0.1.0").first).to include("sem a seção 0.1.0")
    end

    it "RB-RLS-01 o repositório real está sincronizado" do
      output, status = Open3.capture2e("bin/check-version-sync", chdir: RepoPaths::ROOT)

      expect(status).to be_success, output
    end
  end

  describe Tools::ApiCompat do
    let(:baseline) do
      <<~RBS
        module CoffeeMail
          VERSION: String
          class Client
            def initialize: (?api_key: String?, ?locale: String) -> void
            def get: (String id) -> Integer
            attr_reader emails: untyped
          end
          module Internal
            def self.helper: () -> void
          end
        end
      RBS
    end

    it "RB-QA-13 adições são compatíveis" do
      evolved = baseline.sub("def get: (String id) -> Integer",
                             "def get: (String id, ?String extra, ?force: bool) -> Integer\n    def novo: () -> void")

      expect(described_class.breaking_changes([baseline], [evolved])).to be_empty
    end

    it "RB-QA-13 remoção, kwarg removido ou obrigatório e posicional extra quebram" do
      broken = <<~RBS
        module CoffeeMail
          class Client
            def initialize: (api_key: String?) -> void
            def get: (String id, String other) -> Integer
          end
        end
      RBS

      expect(described_class.breaking_changes([baseline], [broken])).to contain_exactly(
        "CoffeeMail::VERSION removido",
        "CoffeeMail::Client#initialize: kwarg locale removido",
        "CoffeeMail::Client#initialize: kwarg api_key virou obrigatório",
        "CoffeeMail::Client#get: exige mais argumentos posicionais",
        "CoffeeMail::Client#emails removido",
      )
    end

    it "RB-QA-13 ignora o namespace Internal e métodos privados" do
      without_internal = baseline.sub(/  module Internal.*?\n  end\n/m, "")
      with_private = baseline.sub("    attr_reader emails: untyped",
                                  "    attr_reader emails: untyped\n    private\n    def x: () -> void")

      expect(described_class.breaking_changes([baseline], [without_internal])).to be_empty
      expect(described_class.breaking_changes([with_private], [baseline])).to be_empty
    end

    it "RB-QA-13 sem tag publicada o gate passa como baseline" do
      output, status = Open3.capture2e("bin/check-api-compat", chdir: RepoPaths::ROOT)

      expect(status).to be_success
      expect(output).to match(/baseline|compatível/)
    end
  end

  it "RB-QA-11 sync-spec --check passa com a fonte igual e falha com divergência" do
    Dir.mktmpdir do |dir|
      altered = File.join(dir, "product.json")
      File.write(altered, JSON.generate(JSON.parse(File.read(RepoPaths.path("openapi/product.json"))).merge("x" => 1)))
      same, same_status = Open3.capture2e({ "COFFEEMAIL_OPENAPI_SPEC" => RepoPaths.path("openapi/product.json") },
                                          "bin/sync-spec", "--check", chdir: RepoPaths::ROOT)
      drift, drift_status = Open3.capture2e({ "COFFEEMAIL_OPENAPI_SPEC" => altered }, "bin/sync-spec", "--check",
                                            chdir: RepoPaths::ROOT)

      expect(same_status).to be_success, same
      expect(drift_status).not_to be_success
      expect(drift).to include("diverge")
    end
  end
end
