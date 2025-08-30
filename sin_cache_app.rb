require 'sinatra'

set server: 'bat_chest'

get '/cached' do
  cache_control 'public', max_age: 60 * 60 * 24 * 7
  sleep 5
  'Expensive response'
end

get '/uncached' do
  cache_control 'no-store'
  sleep 5
  'Fresh expensive response'
end
