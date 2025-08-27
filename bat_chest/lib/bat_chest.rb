# frozen_string_literal: true

require "socket"
require_relative "bat_chest/version"

module BatChest
  class Error < StandardError; end
  class ParseError < Error; end
end

class BatChest::Request
  attr_reader :url, :method, :body, :form_data, :headers

  URLENCODED = "application/x-www-form-urlencoded"

  def initialize(socket)
    parse_req socket.gets

    head = String.new

    loop do
      line = socket.gets
      head << line.chomp("\r").chomp("\n") << "\n"
      break if line.strip == ""
    end

    parse_headers(head)

    return unless @headers["content-type"] == URLENCODED

    len = @headers["content-length"]
    if len
      @body = socket.read(len.to_i)
    else
      error = BatChest::ParseError
      raise error.new("Need length for data!")
    end

    parse_form_body(@body)
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

  def parse_form_body(body)
    data = {}

    body.split(/[;&]/).each do |kv|
      next if kv.empty?

      key, val = kv.split("=", 2)
      data[form_unesc(key)] = form_unesc(val)
    end

    @form_data = data
  end

  def form_unesc(str)
    str = str.gsub("+", " ")
    str.gsub!(/%([0-9a-fA-F]{2})/) { ::Regexp.last_match(1).hex.chr }
    str
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

module BatChest::DSL
  def match_route(route, method: :get, &handler)
    @routes ||= []
    case route
    when String
      p = proc { |u| u.start_with?(route) }
    when Regexp
      p = proc { |u| u.match?(route) }
    else
      raise BatChest::ParseError.new("Unexpected route!")
    end

    @routes << [p, method, handler]
  end

  def get(route, &handler)
    match_route(route, method: :get, &handler)
  end

  def post(route, &handler)
    match_route(route, method: :post, &handler)
  end

  def match(request)
    url = request.url
    method = request.method.downcase.to_sym
    _, _, h = @routes.detect do |p, m, _|
      m == method && p[url]
    end

    if h
      body = request.instance_eval(&h)
      BatChest::Response.new(body, headers: { 'content-type': "text/html" })
    else
      puts "No match"
      BatChest::Response.new("", status: 404, message: "No route found")
    end
  end
end
