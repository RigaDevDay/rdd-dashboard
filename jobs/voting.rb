
require 'firebase'

base_uri = 'https://rigadevdays2017.firebaseio.com/'
firebase = Firebase::Client.new(base_uri)


SCHEDULER.every '5m', :first_in => 0 do |job|

  sessions      = firebase.get('sessions').body
  speakers      = firebase.get('speakers').body
  feedback      = firebase.get('userFeedbacks').body

  voting_data   = Hash[
    sessions.select { |session_id, session_data| session_data.key?('speakers') }.collect do |session_id, session_data|
      speaker     = speakers[session_data['speakers'].first]
      [
        session_id,
        {
            title: session_data['title'],
            avatar: "https://rigadevdays.lv/#{speaker['photoUrl']}",
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
        session_data[:contentPoints] += ratings['qualityOfContent'].to_i
        session_data[:contentVotes] += 1
      end
      if ratings.key?('speakerPerformance') && ratings['speakerPerformance']
        session_data[:speakerPoints] += ratings['speakerPerformance'].to_i
        session_data[:speakerVotes] += 1
      end
      session_data[:totalVotes] = session_data[:speakerVotes] + session_data[:contentVotes]
      session_data[:rate] = session_data[:totalVotes] > 0 ? (session_data[:speakerPoints] + session_data[:contentPoints]) / session_data[:totalVotes] : 0.0
    end
  end

  votes = voting_data
              .map { |session_id, session_data| session_data }
              .select { |session_data| session_data[:rate] > 0 }
              .select { |session_data| session_data[:totalVotes] > 10 }
              .sort { |s1, s2| s2[:rate] <=> s1[:rate] }
              .take(6)

  votes.each { |session| session[:rate] = "%.2f" % session[:rate] }

  send_event('voting', votes: votes)

end

