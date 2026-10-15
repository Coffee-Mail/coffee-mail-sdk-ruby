# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"
  check "lib"
  library "json", "net-http", "openssl", "time", "securerandom", "uri", "timeout"
  configure_code_diagnostics(D::Ruby.strict) do |hash|
    hash[D::Ruby::UnannotatedEmptyCollection] = :hint
  end
end
