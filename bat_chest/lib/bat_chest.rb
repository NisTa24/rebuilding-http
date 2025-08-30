# frozen_string_literal: true

require "socket"
require "rack"
require "stringio"
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

    if @headers["content-type"] == URLENCODED
      len = @headers["content-length"]
      if len
        @body = socket.read(len.to_i)
      else
        error = BatChest::ParseError
        raise error.new("Need length for data!")
      end

      parse_form_body(@body)
    elsif @headers["content-type"] == "application/octet-stream"
      len = @headers["content-length"]

      if len
        @body = socket.read(len.to_i)
      else
        error = BatChest::ParseError
        raise error.new("Need length for data!")
      end
    end
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

  def env
    body = (@body || String.new).encode(Encoding::ASCII_8BIT)
    path, query = @url.split("?", 2)
    env = {
      "REQUEST_METHOD" => @method,
      "SCRIPT_NAME" => "",
      "PATH_INFO" => path,
      "QUERY_STRING" => query || "",
      "SERVER_NAME" => "localhost",
      "SERVER_PORT" => "4444",

      # Rack-specific environment
      "rack.version" => Rack::VERSION,
      "rack.url_scheme" => "http",
      "rack.input" => StringIO.new(body),
      "rack.errors" => STDERR,
      "rack.multithread" => true,
      "rack.multiprocess" => false,
      "rack.run_once" => false,
      "rack.logger" => nil
    }
    @headers.each do |k, v|
      name = "HTTP_" + k.gsub("-", "_").upcase
      env[name] = v
    end
    env
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

class BatChest::Server
  NUM_THREADS = 10
  MAX_WAITING = 20

  def initialize(port, app)
    @server = TCPServer.new(port)
    @queue = Thread::Queue.new
    @app = app
    @port = port
    @pool = (1..NUM_THREADS).map do
      Thread.new { worker_loop }
    end
    @resp_full = BatChest::Response.new("", status: 503, message: "Server too busy!")
  end

  def start
    loop do
      client = @server.accept
      if @queue.num_waiting < MAX_WAITING
        @queue.push(client)
      else
        client.write(@resp_full.to_s)
        client.close
      end
    end
  end

  def worker_loop
    loop do
      client = @queue.pop

      req = BatChest::Request.new(client)
      status, headers, app_body = @app.call(req.env)
      b_text = String.new

      app_body.each { |text| b_text.concat(text) }

      resp = BatChest::Response.new(b_text, status:, headers:)

      client.write resp.to_s
      client.close
    rescue StandardError
      puts "Read error! #{$!.inspect}"
      next
    end
  end
end
