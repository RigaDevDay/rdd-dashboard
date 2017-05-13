
require 'firebase'

base_uri = 'https://rigadevdays2017.firebaseio.com/'
firebase = Firebase::Client.new(base_uri)


SCHEDULER.every '5m', :first_in => 0 do |job|

  sessions      = firebase.get('sessions').body
  speakers      = firebase.get('speakers').body
  feedback      = firebase.get('userFeedbacks').body

  votes         = sessions.select { |session_data| session_data['speakers'] }.map do |session_id, session_data|
    speaker     = speakers[session_data['speakers'].first]
    {
        title: session_data['title'],
        avatar: "https://rigadevdays.lv/#{speaker['photoUrl']}",
        author: speaker['name'],
        speakerPoints: 0.0,
        speakerVotes: 0.0,
        contentPoints: 0.0,
        contentVotes: 0.0
    }
  end

  feedback.each do |user_id, sessionFeedback|
    sessionFeedback.each do |session_id, ratings|
      if ratings['qualityOfContent']

      end
      if ratings['speakerPerformance']

      end

    end
  end

  # voting_data    = JSON.parse(Net::HTTP.get(URI.parse('http://dmi3.net/plusminus/?top')))
  # votes          = voting_data.map do |session|
  #   total_votes  = session['neutral'] + session['plus'] + session['minus']
  #   mark         = session['neutral'] + 2 * session['plus'] - session['minus']
  #   rate         = (mark != 0 ? mark / (2 * total_votes) : 0) * 100
  #   session_item = all_sessions.find { |s| s['subtitle'] == session['title'] }
  #   speaker_id   = session_item ? session_item['speakers'].first : nil
  #   speaker      = speaker_id ? speaker_data.find { |speaker| "#{speaker['id']}" == "#{speaker_id}" } : nil
  #   speaker_name = speaker ? speaker['name'] : ''
  #   avatar       = speaker ? "https://raw.githubusercontent.com/RigaDevDay/RigaDevDay.github.io/master/#{speaker['img']}" : nil
  #   { title: session['title'], avatar: avatar, author: speaker_name, rate: rate, total: total_votes }
  # end
  # votes.sort { |s1, s2| s2[:rate] <=> s1[:rate] }.each { |session| puts "#{session[:title]}: #{session[:rate]} * #{session[:total]}" }
  # votes          = votes.select { |session| session[:rate] > 0 && session[:total] > 10 }.sort { |s1, s2| s2[:rate] <=> s1[:rate] }.take(6)
  # votes.each { |session| session[:rate] = "%.2f%%" % session[:rate] }

  send_event('voting', votes: votes)

end

