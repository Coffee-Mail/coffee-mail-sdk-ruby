# frozen_string_literal: true

# SDK oficial do CoffeeMail para Ruby.
module CoffeeMail
  # Chave do storage de Fiber que guarda o `x-request-id` corrente.
  REQUEST_ID_STORAGE_KEY = :coffeemail_request_id

  # Propaga `x-request-id` em toda requisição feita dentro do bloco, inclusive em threads e fibers filhas.
  #
  # @example
  #   CoffeeMail.with_request_id(request.request_id) { client.emails.send(...) }
  # @param request_id [String]
  # @return [Object] o valor do bloco
  def self.with_request_id(request_id)
    previous = current_request_id
    Fiber[REQUEST_ID_STORAGE_KEY] = request_id.to_s
    begin
      yield
    ensure
      Fiber[REQUEST_ID_STORAGE_KEY] = previous
    end
  end

  # @return [String, nil] o `x-request-id` do bloco {with_request_id} corrente
  def self.current_request_id = Fiber[REQUEST_ID_STORAGE_KEY]
end
