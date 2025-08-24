RUBY_MAIN = self

require_relative "../bat_chest"
include BatChest::DSL

at_exit do
  server = TCPServer.new 4321
  loop do
    client = server.accept
    req = BatChest::Request.new(client)
    resp = RUBY_MAIN.match(req.url)
    client.write resp.to_s
    client.close
  rescue StandardError
    puts "Read error! #{$!.inspect}"
    next
  end
end
