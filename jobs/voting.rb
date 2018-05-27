
require 'firebase'
require 'cgi'

base_uri = 'https://riga-dev-days-2018.firebaseio.com/'
firebase = Firebase::Client.new(base_uri)


SCHEDULER.every '5m', :first_in => 0 do |job|

  sessions      = firebase.get('sessions').body
  speakers      = firebase.get('speakers').body
  feedback      = firebase.get('userFeedbacks').body

  voting_data   = Hash[
      sessions.select { |session_id, session_data| session_data.key?('speakers') }.collect do |session_id, session_data|
        speaker     = speakers[session_data['speakers'].first]

        urlClean     = CGI.escape(speaker['photoUrl'].gsub('/images', 'images'))
        avatar       = "https://firebasestorage.googleapis.com/v0/b/riga-dev-days-2018.appspot.com/o/#{urlClean}?alt=media"

        [
            session_id,
            {
                title: session_data['title'],
                avatar: avatar,
                author: speaker['name'],
                speakerPoints: 0.0,
                speakerVotes: 0.0,
                contentPoints: 0.0,
                contentVotes: 0.0,
                rate: 0.0
            }
        ]
      end
  ]

  feedback.each do |user_id, session_feedback|
    session_feedback.each do |session_id, ratings|
      session_data = voting_data[session_id.to_s]
      if ratings.key?('qualityOfContent') && ['qualityOfContent']
        r = ratings['qualityOfContent'].to_i
        if r > 0
          session_data[:contentPoints] += r
          session_data[:contentVotes] += 1
        end
      end
      if ratings.key?('speakerPerformance') && ratings['speakerPerformance']
        r = ratings['speakerPerformance'].to_i
        if r > 0
          session_data[:speakerPoints] += r
          session_data[:speakerVotes] += 1
        end
      end
      session_data[:totalVotes] = session_data[:speakerVotes] + session_data[:contentVotes]
      session_data[:rate] = session_data[:totalVotes] > 0 ? (session_data[:speakerPoints] + session_data[:contentPoints]) / session_data[:totalVotes] : 0.0
    end
  end

  votes = voting_data
              .map { |session_id, session_data| session_data }
              .select { |session_data| session_data[:rate] > 0 }
              .select { |session_data| session_data[:totalVotes] > 30 }
              .sort { |s1, s2| s2[:rate] <=> s1[:rate] }
              .take(6)

  votes.each { |session| session[:rate] = "%.2f" % session[:rate] }

  send_event('voting', votes: votes)

end
