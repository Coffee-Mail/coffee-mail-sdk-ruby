# frozen_string_literal: true

module RepoPaths
  ROOT = File.expand_path("../..", __dir__)

  module_function

  def path(*parts) = File.join(ROOT, *parts)
end
