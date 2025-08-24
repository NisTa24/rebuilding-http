require_relative "lib/bat_chest"

server = TCPServer.new 4321

loop do
  client = server.accept

  BatChest::Request.new(client)
  resp = BatChest::Response.new("Holy heck!!! BatChest")
  client.write resp.to_s
  client.close
rescue StandardError
  puts "Read error!: #{$!.inspect}"
  next
end
