
require 'json'
require 'net/http'
require 'active_support/time'
require 'uri'

# github_uri       = URI.parse('https://raw.githubusercontent.com/')
# http             = Net::HTTP.new(github_uri.host, github_uri.port)
# http.use_ssl     = true
# http.verify_mode = OpenSSL::SSL::VERIFY_NONE
#
# event_data       = JSON.parse(http.get('/RigaDevDay/RigaDevDay.github.io/master/assets/data/main.json').body)
# speaker_data     = event_data['speakers']
# schedule_data    = event_data['days'][Date.today.day % 2]
# schedule_data2   = event_data['days'][Date.today.day % 2 == 0 ? 1 : 0]
#
# schedule         = schedule_data['schedule']['schedule']
# schedule2        = schedule_data2['schedule']['schedule']
# sessions         = schedule.map { |time_slot| time_slot['events'] }.flatten
# all_sessions     = schedule2.map { |time_slot| time_slot['events'] }.flatten.concat(sessions)
#
# SCHEDULER.every '2m', :first_in => 0 do |job|
#   voting_data    = JSON.parse(Net::HTTP.get(URI.parse('http://dmi3.net/plusminus/?top')))
#   votes          = voting_data.map do |session|
#     total_votes  = session['neutral'] + session['plus'] + session['minus']
#     mark         = session['neutral'] + 2 * session['plus'] - session['minus']
#     rate         = (mark != 0 ? mark / (2 * total_votes) : 0) * 100
#     session_item = all_sessions.find { |s| s['subtitle'] == session['title'] }
#     speaker_id   = session_item ? session_item['speakers'].first : nil
#     speaker      = speaker_id ? speaker_data.find { |speaker| "#{speaker['id']}" == "#{speaker_id}" } : nil
#     speaker_name = speaker ? speaker['name'] : ''
#     avatar       = speaker ? "https://raw.githubusercontent.com/RigaDevDay/RigaDevDay.github.io/master/#{speaker['img']}" : nil
#     { title: session['title'], avatar: avatar, author: speaker_name, rate: rate, total: total_votes }
#   end
#   votes.sort { |s1, s2| s2[:rate] <=> s1[:rate] }.each { |session| puts "#{session[:title]}: #{session[:rate]} * #{session[:total]}" }
#   votes          = votes.select { |session| session[:rate] > 0 && session[:total] > 10 }.sort { |s1, s2| s2[:rate] <=> s1[:rate] }.take(6)
#   votes.each { |session| session[:rate] = "%.2f%%" % session[:rate] }
#   send_event('voting', votes: votes)
# end
#

