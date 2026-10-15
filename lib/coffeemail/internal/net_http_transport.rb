# frozen_string_literal: true

require "net/http"
require "uri"

module CoffeeMail
  module Internal
    class NetHttpTransport
      REQUEST_CLASSES = {
        "GET" => Net::HTTP::Get,
        "POST" => Net::HTTP::Post,
        "PUT" => Net::HTTP::Put,
        "PATCH" => Net::HTTP::Patch,
        "DELETE" => Net::HTTP::Delete,
      }.freeze

      def call(request)
        uri = URI(request.url)
        net_request = build(request, uri)
        Net::HTTP.start(uri.host.to_s, uri.port, **connection_options(uri, request.timeout)) do |http|
          to_response(http.request(net_request))
        end
      end

      private

      def build(request, uri)
        net_request = REQUEST_CLASSES.fetch(request.http_method).new(uri)
        request.headers.each { |name, value| net_request[name] = value }
        net_request.body = request.body if request.body
        net_request
      end

      def connection_options(uri, timeout)
        {
          use_ssl: uri.scheme == "https",
          open_timeout: timeout,
          read_timeout: timeout,
          write_timeout: timeout,
          ssl_timeout: timeout,
        }
      end

      def to_response(net_response)
        headers = net_response.each_header.to_h { |name, value| [name.downcase, value] }
        HttpResponse.new(status: net_response.code.to_i, headers: headers, body: net_response.body.to_s)
      end
    end
  end
end
