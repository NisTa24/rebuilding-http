RUBY_MAIN = self

require_relative "../bat_chest"
include BatChest::DSL

at_exit do
  server = BatChest::Server.new(4321)
  server.start
end
