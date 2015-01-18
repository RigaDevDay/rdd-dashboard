require 'twitter'
require 'yaml'

conference_config = YAML.load_file('rigadevday.yml')

twitter = Twitter::REST::Client.new do |config|
  config.consumer_key = conference_config['consumer_key']
  config.consumer_secret = conference_config['consumer_secret']
  config.access_token = conference_config['access_token']
  config.access_token_secret = conference_config['access_token_secret']
end

search_term = URI::encode('#rigadevday')

SCHEDULER.every '10m', :first_in => 0 do |job|
  begin
    tweets = twitter.search("#{search_term}")
    if tweets
      tweets = tweets.map do |tweet|
        { name: tweet.user.name, body: tweet.text, avatar: tweet.user.profile_image_url_https }
      end
      send_event('twitter_mentions', comments: tweets)
    end
  rescue Twitter::Error
    puts "\e[33mFor the twitter widget to work, you need to put in your twitter API keys in the jobs/twitter.rb file.\e[0m"
  end
end