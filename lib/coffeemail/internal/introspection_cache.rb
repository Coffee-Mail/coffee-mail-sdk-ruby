# frozen_string_literal: true

module CoffeeMail
  module Internal
    class IntrospectionCache
      Entry = Data.define(:response, :stored_at)

      def initialize(requester, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
        @requester = requester
        @clock = clock
        @mutex = Mutex.new
        @entry = nil
      end

      def fetch(force_refresh:)
        @mutex.synchronize do
          entry = @entry
          return entry.response if entry && !force_refresh && fresh?(entry)

          response = @requester.call(operation)
          @entry = response.success? ? Entry.new(response: response, stored_at: @clock.call) : nil
          response
        end
      end

      def invalidate
        @mutex.synchronize { @entry = nil }
      end

      private

      def fresh?(entry)
        @clock.call - entry.stored_at < Constants::Defaults::INTROSPECTION_TTL_SECONDS
      end

      def operation
        Operation.build(name: "introspect", http_method: "GET", path: Constants::Routes::API_KEY_INTROSPECTION,
                        decoder: Model.object(Models::ApiKeyInfo))
      end
    end
  end
end
