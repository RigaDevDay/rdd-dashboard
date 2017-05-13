
require 'active_support/time'
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

  current_slot  = time_slots.select { |time_slot| to_min(time_slot['startTime']) > current_min + 15 }.first
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
      if room_name && (room_name.include? "SCAPE")
        room_name = 'SCAPE'
      end
      unless avatar
        room_name = 'HALL'
        if current_session['title'].downcase.include? "coffee"
          avatar = '/assets/coffee_break.png'
        elsif current_session['title'].downcase.include? "lunch"
          avatar = '/assets/lunch.png'
        elsif current_session['title'].downcase.include? "closing"
          avatar = '/assets/favicon.png'
          room_name = 'SCAPE'
        elsif current_session['title'].downcase.include? "opening"
          avatar = '/assets/favicon.png'
          room_name = 'SCAPE'
        elsif current_session['title'].downcase.include? "party"
          avatar = '/assets/party.png'
        else
          avatar = '/assets/favicon.png'
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
    send_event('schedule', sessions: current_sessions.select { |session| session[:title].downcase != 'tbd' })
  end
end

