require "socket"

ASSIGNED_IDS = {}

threads = (1..10).map do |_tn|
  Thread.new do
    100.times do
      id_resp = `curl -s http://localhost:4321/new_id`

      id = id_resp.to_i
      raise "Duplicate. ID!" + "  #{ASSIGNED_IDS.keys.inspect}" if ASSIGNED_IDS[id]

      ASSIGNED_IDS[id] = true
    end
  end
end

threads.each { |t| t.join }

puts "Made it to the end with only unique IDs!"
puts ASSIGNED_IDS.inspect
