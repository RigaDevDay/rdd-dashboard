
tracks = 5
sessions = 33
attendees = 400

SCHEDULER.every '2s' do

  send_event('tracks', { current: tracks, last: tracks })
  send_event('sessions', { current: sessions, last: sessions })
  send_event('attendees', { current: attendees, last: attendees })

end