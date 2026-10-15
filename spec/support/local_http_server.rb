# frozen_string_literal: true

require "socket"

class LocalHttpServer
  attr_reader :port, :received

  def initialize(response: nil, delay: 0)
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @response = response || "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nX-Request-Id: req-1\r\n" \
                            "Content-Length: 11\r\nConnection: close\r\n\r\n{\"ok\":true}"
    @delay = delay
    @received = Queue.new
    @thread = Thread.new { serve }
  end

  def url(path = "/") = "http://127.0.0.1:#{port}#{path}"

  def close
    @thread.kill
    @server.close
  end

  private

  def serve
    socket = @server.accept
    request = read_request(socket)
    @received << request
    sleep(@delay)
    socket.write(@response)
    socket.close
  end

  def read_request(socket)
    head = +""
    head << socket.readpartial(4096) until head.include?("\r\n\r\n")
    length = head[/content-length: (\d+)/i, 1].to_i
    header_part, body = head.split("\r\n\r\n", 2)
    body << socket.readpartial(4096) while body.bytesize < length
    { head: header_part, body: body }
  end
end
