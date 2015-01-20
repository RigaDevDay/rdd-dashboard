
require 'twitter'
require 'active_support/time'
require 'yaml'
require 'sqlite3'
require 'active_record'

###########################################################################
# Create database and configure connectivity
###########################################################################
db = SQLite3::Database.new "/var/lib/sqlite/rigadevday.db"

[
  'CREATE TABLE IF NOT EXISTS TWEETS(ID TEXT, CREATED_AT TEXT);',
  'CREATE UNIQUE INDEX IF NOT EXISTS TWEET_ID ON TWEETS (ID);',
  'CREATE INDEX TWEET_DATE IF NOT EXISTS ON TWEETS (CREATED_AT);'
].each { |sql| db.execute(sql) }

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => '/var/lib/sqlite/rigadevday.db'
)

class Tweet < ActiveRecord::Base
end


###########################################################################
# Configure Twitter client
###########################################################################

conference_config = YAML.load_file('/etc/rigadevday.yml')

twitter = Twitter::REST::Client.new do |config|
  config.consumer_key = conference_config['consumer_key']
  config.consumer_secret = conference_config['consumer_secret']
  config.access_token = conference_config['access_token']
  config.access_token_secret = conference_config['access_token_secret']
end

search_term = URI::encode('#rigadevday')

SCHEDULER.every '30s', :first_in => 0 do |job|
  begin
    tweets = twitter.search("#{search_term}", { :result_type => 'recent', :count => 100 })
    tweets.each do |tweet|
      t = Tweet.new
      t.id = tweet.id
      t.created_at = tweet.created_at.in_time_zone('Europe/Riga').strftime("%m-%d %H:%M:%S")
      t.save
    end
    if tweets
      tweets = tweets.select { |tweet| !tweet.text.start_with?('RT') }.take(20).map do |tweet|
        { name: tweet.user.name, time: tweet.created_at.in_time_zone('Europe/Riga').strftime("%m-%d %H:%M:%S"), body: tweet.text, avatar: tweet.user.profile_image_url_https }
      end
      send_event('twitter_mentions', comments: tweets)
    end
    stats = []
    # TODO: select tweet stats from database
    (1..10).each do |i|
      stats << { x: i, y: rand(50) }
    end
    send_event('twitter_activity', { graphtype: 'bar', points: stats })
  rescue Twitter::Error
    puts "\e[33mFor the twitter widget to work, you need to put in your twitter API keys in the jobs/twitter.rb file.\e[0m"
  end
end

