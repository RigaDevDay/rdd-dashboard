
# TODO: read data from a file
tracks = 5
speakers = 28
sessions = 33
attendees = 300

SCHEDULER.every '60s' do

  send_event('tracks', { value: tracks })
  send_event('speakers', { value: speakers })
  send_event('sessions', { value: sessions })
  send_event('attendees', { value: attendees })

end