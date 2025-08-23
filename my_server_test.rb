# frozen_string_literal: true

# NOTE: shut down the server if it is already running

MY_SERVER = File.join(__dir__, 'my_server.rb')

Thread.new do
  system "ruby #{MY_SERVER}"
end

sleep 0.1

if `curl -v http://localhost:4321`.include?('Hello World!')
  puts 'Success!'
else
  puts 'Failure!'
end
