# require "rack"
# require "rack/handler"
# NOTE: using "Rack::Handler::" doesn't work as described in the book. It probably used to work in 2021
require "rackup/handler"
require_relative "../../bat_chest"

class Rackup::Handler::BatChest
  def self.run(app, config)
    port = config[:port] || "4567"
    puts "Starting BatChest on port #{port}"

    server = BatChest::Server.new(port, app)
    server.start
  end
end

# Rack::Handler.register :bat_chest, ::Rack::Handler::BatChest
Rackup::Handler.register :bat_chest, ::Rackup::Handler::BatChest
