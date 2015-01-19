
require 'json'
require 'net/http'
require 'uri'

github_uri       = URI.parse('https://raw.githubusercontent.com/')
http             = Net::HTTP.new(github_uri.host, github_uri.port)
http.use_ssl     = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

schedule_data    = JSON.parse(http.get('/RigaDevDay/RigaDevDay.github.io/master/data/schedule.json').body)
speaker_data     = JSON.parse(http.get('/RigaDevDay/RigaDevDay.github.io/master/data/speakers.json').body)

rooms            = schedule_data['roomNames']
schedule         = schedule_data['schedule']

def to_min(time_code)
   return (time_code / 100) * 60 + time_code % 100
end


SCHEDULER.every '10m', :first_in => 0 do |job|
  current_time = Time.now
  current_min  = to_min("#{current_time.hour}#{current_time.min}".to_i)
  time_slots   = schedule.map do |time_slot|
    { :time_code => time_slot['time'].split(':').join('').to_i, :events => time_slot['events'] }
  end
  current_slot = time_slots.select { |time_slot| to_min(time_slot[:time_code]) > current_min + 15 }.first
  if current_slot
    sessions = current_slot['events'].map do |event|
      { name: event['subtitle'], body: event['description'] }
    end
    send_event('schedule', sessions: sessions)
  end
end