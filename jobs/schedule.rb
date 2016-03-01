
require 'json'
require 'net/http'
require 'active_support/time'
require 'uri'

github_uri       = URI.parse('https://raw.githubusercontent.com/')
http             = Net::HTTP.new(github_uri.host, github_uri.port)
http.use_ssl     = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

event_data       = JSON.parse(http.get('/RigaDevDay/RigaDevDay.github.io/master/assets/data/main.json').body)
speaker_data     = event_data['speakers']
schedule_data    = event_data['days'][Date.today.day % 2]

schedule         = schedule_data['schedule']['schedule']
rooms            = schedule_data['schedule']['roomNames']

def to_min(time_code)
  return (time_code / 100) * 60 + time_code % 100
end


SCHEDULER.every '1m', :first_in => 0 do |job|
  current_time = Time.now.in_time_zone('Europe/Riga')
  current_min  = current_time.hour * 60 + current_time.min
  time_slots   = schedule.map do |time_slot|
    { :time => time_slot['time'], :time_code => time_slot['time'].split(':').join('').to_i, :events => time_slot['events'] }
  end
  current_slot = time_slots.select { |time_slot| to_min(time_slot[:time_code]) > current_min + 15 }.first
  current_slot ||= time_slots.last
  if current_slot
    sessions       = current_slot[:events].each_with_index.map do |event, i|
      speaker_id   = event['speakers'] ? event['speakers'].first : nil
      speaker      = speaker_id ? speaker_data.find { |speaker| "#{speaker['id']}" == "#{speaker_id}" } : nil
      avatar       = speaker ? "https://raw.githubusercontent.com/RigaDevDay/RigaDevDay.github.io/master/#{speaker['img']}" : nil
      room_name    = rooms[i]
      if !avatar && event['title']
        room_name = 'HALL'
        if event['title'].include? "Coffee"
          avatar    = '/assets/coffee_break.png'
        elsif event['title'].include? "Lunch"
          avatar    = '/assets/lunch.png'
        elsif event['title'].include? "Closing"
          avatar    = '/assets/favicon.png'
        elsif event['title'].include? "Opening"
          avatar    = '/assets/favicon.png'
        elsif event['title'].include? "Afterparty"
          avatar    = '/assets/party.png'
        else
          avatar    = '/assets/favicon.png'
        end          
      end
      speaker      = speaker_id ? speaker_data.find { |speaker| "#{speaker['id']}" == "#{speaker_id}" } : nil
      speaker_name = speaker ? speaker['name'] : ''
      {
         title: "#{event['title']} #{event['subtitle']}",
         description: event['description'],
         avatar: avatar,
         author: speaker_name,
         time: current_slot[:time],
         room: room_name
      }
    end
    send_event('schedule', sessions: sessions)
  end
end

