# frozen_string_literal: true

require "socket"
require_relative "bat_chest/version"

module BatChest
  class Error < StandardError; end
  class ParseError < Error; end
end

class BatChest::Request
  attr_reader :url

  def initialize(socket)
    parse_req socket.gets

    head = String.new

    loop do
      line = socket.gets
      head << line.chomp("\r").chomp("\n") << "\n"
      break if line.strip == ""
    end

    parse_headers(head)
  end

  def parse_req(line)
    @method, @url, rest = line.split(/\s/, 3)

    raise BatChest::ParseError.new("Can't parse request") unless rest =~ %r{HTTP/(\d+)\.(\d+)}

    @http_version = "#{::Regexp.last_match(1)}.#{::Regexp.last_match(2)}"
  end

  def parse_headers(text)
    @headers = {}
    text.lines.each do |line|
      break if line.strip.empty?

      field, value = line.split(":", 2)
      @headers[field.downcase] = value.strip
    end
  end
end

class BatChest::Response
  def initialize(body,
                 version: "1.1",
                 status: 200,
                 message: "OK",
                 headers: {})
    @version = version
    @status = status
    @message = message
    @headers = headers
    @body = body
  end

  def to_s
    lines = [
      "HTTP/#{@version} #{@status} #{@message}"
    ] + @headers.map { |k, v| "#{k}: #{v}" } + ["", @body, ""]

    lines.join("\r\n")
  end
end
