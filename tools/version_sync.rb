# frozen_string_literal: true

module Tools
  module VersionSync
    RELEASED_HEADING = /^## \[(\d+\.\d+\.\d+)\]/
    USER_AGENT_TEMPLATE = "coffeemail-ruby/\#{CoffeeMail::VERSION}"

    module_function

    def problems(version:, gemspec_version:, headers_source:, changelog:, tag: nil)
      [
        gemspec_problem(version, gemspec_version),
        user_agent_problem(headers_source),
        changelog_problem(version, changelog),
        tag_problem(version, changelog, tag),
      ].compact
    end

    def gemspec_problem(version, gemspec_version)
      return nil if version == gemspec_version

      "gemspec declara #{gemspec_version}, CoffeeMail::VERSION é #{version}"
    end

    def user_agent_problem(headers_source)
      return nil if headers_source.include?(USER_AGENT_TEMPLATE)

      "User-Agent não deriva de CoffeeMail::VERSION (esperado #{USER_AGENT_TEMPLATE})"
    end

    def changelog_problem(version, changelog)
      newest = changelog.scan(RELEASED_HEADING).flatten.first
      return nil if newest.nil? || Gem::Version.new(newest) <= Gem::Version.new(version)

      "CHANGELOG já tem #{newest}, mais nova que CoffeeMail::VERSION #{version}"
    end

    def tag_problem(version, changelog, tag)
      return nil if tag.nil?
      return "tag #{tag} não corresponde a CoffeeMail::VERSION #{version}" unless tag == "v#{version}"
      return nil if changelog.match?(/^## \[#{Regexp.escape(version)}\]/)

      "CHANGELOG sem a seção #{version}"
    end
  end
end
