# frozen_string_literal: true

module CoffeeMail
  # Requisição entregue ao transporte.
  #
  # Um transporte é qualquer objeto com `call(HttpRequest) -> HttpResponse`.
  class HttpRequest < Data.define(:http_method, :url, :headers, :body, :timeout)
    # @return [String]
    def inspect
      visible = headers.reject { |name, _| name == Internal::Constants::Headers::AUTHORIZATION }
      "#<CoffeeMail::HttpRequest #{http_method} #{url} headers=#{visible.inspect}>"
    end

    # @return [String]
    def to_s = inspect
  end

  # Resposta devolvida pelo transporte. Os nomes de header são minúsculos.
  class HttpResponse < Data.define(:status, :headers, :body)
    # @param name [String]
    # @return [String, nil]
    def header(name)
      headers[name.downcase]
    end
  end
end
