# frozen_string_literal: true

module CoffeeMail
  module Internal
    module Paginator
      START = Object.new.freeze
      DONE = Object.new.freeze
      Page = Data.define(:response, :offset)

      module_function

      def cursor(&fetch)
        Enumerator.produce(START) { |previous| next_cursor_page(previous, fetch) }
                  .lazy.drop(1).take_while { |response| !response.equal?(DONE) }
      end

      def offset(start, &fetch)
        Enumerator.produce(START) { |previous| next_offset_page(previous, start, fetch) }
                  .lazy.drop(1).take_while { |page| !page.equal?(DONE) }.map { |page| response_of(page) }
      end

      def next_cursor_page(previous, fetch)
        return fetch.call(nil) if previous.equal?(START)
        return DONE if previous.failure? || previous.data.next_cursor.nil?

        fetch.call(previous.data.next_cursor)
      end

      def next_offset_page(previous, start, fetch)
        return Page.new(response: fetch.call(start), offset: start) if previous.equal?(START)

        following = following_offset(previous)
        return DONE if following.nil?

        Page.new(response: fetch.call(following), offset: following)
      end

      def following_offset(previous)
        return nil if previous.response.failure?

        data = previous.response.data
        items = offset_items(data)
        following = previous.offset + items.size
        items.empty? || following >= data.total.to_i ? nil : following
      end

      def response_of(page) = page.response

      def offset_items(data)
        data.respond_to?(:contacts) ? data.contacts.to_a : data.audiences.to_a
      end
    end
  end
end
