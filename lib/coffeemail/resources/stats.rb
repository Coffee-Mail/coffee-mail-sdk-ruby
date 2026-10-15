# frozen_string_literal: true

module CoffeeMail
  module Resources
    # Estatísticas de envio (`/v1/product/stats`).
    class Stats < Base
      include Internal::Constants

      # @return [Response] com {Models::Stats}
      def get(domain_id: nil, tag: nil, start_date: nil, end_date: nil, granularity: nil, period: nil,
              email_type: nil)
        filters = { domain_id:, tag:, start_date:, end_date:, granularity:, period:, email_type: }
        request("get", Verbs::GET, Routes::STATS, object(Models::Stats), query: query(filters, Internal::Fields::STATS))
      end
    end
  end
end
