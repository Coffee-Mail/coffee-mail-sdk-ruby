# frozen_string_literal: true

module CoffeeMail
  module Internal
    module Backoff
      GROWTH_FACTOR = 2

      module_function

      def delay(policy, attempt, retry_after, random)
        return [retry_after, policy.max_delay].min.to_f if retry_after

        ceiling = [policy.base_delay.to_f * (GROWTH_FACTOR**(attempt - 1)), policy.max_delay.to_f].min
        random.rand * ceiling.to_f
      end
    end
  end
end
