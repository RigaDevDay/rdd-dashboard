
require 'json'
require 'net/http'
require 'active_support/time'
require 'uri'
require 'firebase'


base_uri = 'https://rigadevdays2017.firebaseio.com/'
firebase = Firebase::Client.new(base_uri)


def to_min(time_str)
  time_code = time_str.split(':').join('').to_i
  (time_code / 100) * 60 + time_code % 100
end


SCHEDULER.every '1m', :first_in => 0 do |job|

  current_time  = Time.now.in_time_zone('Europe/Riga')
  current_min   = current_time.hour * 60 + current_time.min

  full_schedule = firebase.get('schedule').body
  sessions      = firebase.get('sessions').body
  speakers      = firebase.get('speakers').body

  day_schedule  = full_schedule[(Date.today.day + 1) % 2]
  time_slots    = day_schedule['timeslots']
  rooms         = day_schedule['tracks']

  current_slot  = time_slots.select { |time_slot| to_min(time_slot['startTime']) > current_min - 350 }.first
  current_slot  ||= time_slots.last

  if current_slot
    puts "Sending schedule for: #{current_slot['startTime']}"
    current_sessions   = current_slot['sessions'].each_with_index.map do |session, i|
      current_session  = sessions[session.first.to_s]
      avatar           = nil
      speaker_name     = nil
      room_name        = current_session['auditorium'] ? current_session['auditorium'] : rooms[i]['title']
      if current_session['speakers']
        speaker        = speakers[current_session['speakers'].first]
        if speaker
          speaker_name = speaker['name']
          avatar       = "https://rigadevdays.lv/#{speaker['photoUrl']}"
        end
      end
      {
         title: "#{current_session['title']}",
         description: current_session['description'],
         avatar: avatar,
         author: speaker_name,
         time: current_slot['startTime'],
         room: room_name
      }
    end
    send_event('schedule', sessions: current_sessions)
  end
  # time_slots   = schedule.map do |time_slot|
  #   { :time => time_slot['time'], :time_code => time_slot['time'].split(':').join('').to_i, :events => time_slot['events'] }
  # end
  # current_slot = time_slots.select { |time_slot| to_min(time_slot[:time_code]) > current_min + 15 }.first
  # current_slot ||= time_slots.last
  # if current_slot
  #   sessions       = current_slot[:events].each_with_index.map do |event, i|
  #     speaker_id   = event['speakers'] ? event['speakers'].first : nil
  #     speaker      = speaker_id ? speaker_data.find { |speaker| "#{speaker['id']}" == "#{speaker_id}" } : nil
  #     avatar       = speaker ? "https://raw.githubusercontent.com/RigaDevDay/RigaDevDay.github.io/master/#{speaker['img']}" : nil
  #     room_name    = rooms[i]
  #     if event['subtitle'].include? "Open Source and OpenJDK"
  #       room_name  = 'Room 2'
  #     end
  #     if event['subtitle'].include? "The Web - What it Has"
  #       room_name  = 'Room 2'
  #     end
  #     if !avatar && event['title']
  #       room_name = 'HALL'
  #       if event['title'].include? "Coffee"
  #         avatar    = '/assets/coffee_break.png'
  #       elsif event['title'].include? "Lunch"
  #         avatar    = '/assets/lunch.png'
  #       elsif event['title'].include? "Closing"
  #         avatar    = '/assets/favicon.png'
  #         room_name = 'Room 2'
  #       elsif event['title'].include? "Opening"
  #         avatar    = '/assets/favicon.png'
  #         room_name = 'Room 2'
  #       elsif event['title'].include? "Afterparty"
  #         avatar    = '/assets/party.png'
  #       else
  #         avatar    = '/assets/favicon.png'
  #       end
  #     end
  #     speaker      = speaker_id ? speaker_data.find { |speaker| "#{speaker['id']}" == "#{speaker_id}" } : nil
  #     speaker_name = speaker ? speaker['name'] : ''
  #     {
  #        title: "#{event['title']} #{event['subtitle']}",
  #        description: event['description'],
  #        avatar: avatar,
  #        author: speaker_name,
  #        time: current_slot[:time],
  #        room: room_name
  #     }
  #   end
  #   send_event('schedule', sessions: sessions)
  # end
end

