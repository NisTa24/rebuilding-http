require 'sinatra'
require 'digest'

set server: 'bat_chest'

get '/etagged' do
  ctr = Time.now.to_i / 30
  text = "Content: #{ctr}"

  tag = Digest::SHA2.hexdigest text

  cache_control :public, max_age: 0
  etag(tag)
  warn 'Uncached!'

  text
end
