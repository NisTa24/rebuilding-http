require "socket"

def bad_client_conn
  server = TCPSocket.new "localhost", 4321
  server.write "GET / HTTP/1.1\r\nHost:"
  server
end

bad_conns = (1..8).map { bad_client_conn }
good_out = `curl -s http://localhost:4321/`
puts good_out

more_bad_conns = (1..4).map { bad_client_conn }
try_out = `curl -s http://localhost:4321/`
puts try_out
