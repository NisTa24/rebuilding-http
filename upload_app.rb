require 'sinatra'

set server: 'bat_chest'

post '/upload/:f' do
  File.open(params['f'], 'w') do |f|
    request.body.rewind
    f.write(request.body.read)
  end
  "OK\n"
end
