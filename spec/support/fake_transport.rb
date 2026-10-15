# frozen_string_literal: true

class FakeTransport
  JSON_HEADERS = { "content-type" => "application/json" }.freeze

  attr_reader :requests

  def initialize(*responses)
    @responses = responses
    @requests = []
  end

  def self.json(status, body, headers = {})
    new(reply(status, body, headers))
  end

  def self.reply(status, body, headers = {})
    payload = body.is_a?(String) ? body : JSON.generate(body)
    CoffeeMail::HttpResponse.new(status: status, headers: JSON_HEADERS.merge(headers), body: payload)
  end

  def call(request)
    @requests << request
    next_response = @responses.size > 1 ? @responses.shift : @responses.first
    raise next_response if next_response.is_a?(Exception)

    next_response.respond_to?(:call) ? next_response.call(request) : next_response
  end

  def last = requests.last

  def last_body = JSON.parse(last.body)

  def last_query = URI.decode_www_form(URI(last.url).query.to_s).to_h

  def last_path = URI(last.url).path
end

API_KEY = "cm_test_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

module ClientHelpers
  def client_with(transport, **options)
    CoffeeMail::Client.new(api_key: API_KEY, transport: transport, **options)
  end
end

RSpec.configure { |config| config.include ClientHelpers }
