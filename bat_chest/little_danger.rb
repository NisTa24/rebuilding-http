STATE = { ctr: 0 }

get "/new_id" do
  STATE[:ctr] += 1
  sleep 0.005
  STATE[:ctr].to_s
end
