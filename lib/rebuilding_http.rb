require 'socket'

HELLO_WORLD_RESPONSE = <<~TEXT
  HTTP/1.1 200 OK
  Content-Type: text/plain

  Hello World!
TEXT

module RHTTP
  def read_request(sock)
    out = ''

    loop do
      line = sock.gets
      out << line.chomp << "\n"

      return out if line.strip == ''
    end
  end

  def get_request(sock)
    req_text = read_request(sock)
    RHTTP::Request.new(req_text)
  end
end

class RHTTP::Request
  attr_reader :method, :url, :http_version, :headers

  def initialize(text)
    # splits texts into lines
    lines = text.split(/\r\n|\n\r|\r|\n/)
    @method, @url, rest = lines[0].split(/\s/, 3)

    # uses regexp to parse HTTP version like HTTP/1.1
    @http_version = "#{::Regexp.last_match(1)}.#{::Regexp.last_match(2)}" if rest =~ %r{HTTP/(\d+)\.(\d+)}

    @headers = lines[1..-1].join("\n")
  end
end
