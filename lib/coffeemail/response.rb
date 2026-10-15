# frozen_string_literal: true

module CoffeeMail
  # Envelope de toda operação: traz `data` no sucesso ou `error` na falha, nunca os dois.
  #
  # @example Desestruturação
  #   data, error = client.emails.get(id)
  # @example Pattern matching
  #   client.emails.get(id) => { data: }
  class Response < Data.define(:data, :error, :status)
    # @param data [Object]
    # @param status [Integer]
    # @return [Response]
    def self.success(data, status)
      new(data: data, error: nil, status: status)
    end

    # @param error [Error]
    # @return [Response]
    def self.failure(error)
      new(data: nil, error: error, status: error.status)
    end

    # @return [Boolean]
    def success? = error.nil?

    # @return [Boolean]
    def failure? = !success?

    # @return [Array(Object, Error)] `[data, error]`, para `data, error = response`
    def to_ary = [data, error]

    # Devolve `data` ou levanta o erro.
    # @return [Object]
    # @raise [Error]
    def unwrap!
      raise error if error

      data
    end
  end
end
