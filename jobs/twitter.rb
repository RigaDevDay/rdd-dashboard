
require 'twitter'
require 'active_support/time'
require 'yaml'
require 'sqlite3'
require 'active_record'
require 'htmlentities'
require 'fastimage'


###########################################################################
# Load configuration parameters.
###########################################################################

db_path = "/var/lib/sqlite/rigadevday.db"
global_config = YAML.load_file('/etc/rigadevday.yml')

twitter = Twitter::REST::Client.new do |config|
  config.consumer_key = global_config['consumer_key']
  config.consumer_secret = global_config['consumer_secret']
  config.access_token = global_config['access_token']
  config.access_token_secret = global_config['access_token_secret']
end

search_query = URI::encode('#rigadevday OR #rigadevdays OR @rigadevdays')
accounts = global_config['twitter_accounts'] || [ '@rigadevdays' ]

###########################################################################
# Create database and configure connectivity.
###########################################################################

db = SQLite3::Database.new db_path

[
    'CREATE TABLE IF NOT EXISTS TWEETS(ID TEXT, CONTENT TEXT, AVATAR TEXT, NAME TEXT, CREATED_AT TEXT);',
    'CREATE UNIQUE INDEX IF NOT EXISTS TWEET_ID ON TWEETS (ID);',
    'CREATE INDEX IF NOT EXISTS TWEET_DATE ON TWEETS (CREATED_AT);',
    'CREATE INDEX IF NOT EXISTS TWEET_NAME ON TWEETS (NAME);',
    'CREATE INDEX IF NOT EXISTS TWEET_CONTENT ON TWEETS (CONTENT);',
    'CREATE TABLE IF NOT EXISTS MEDIA(ID TEXT, SHORT_URI TEXT, URI TEXT, WIDTH INTEGER, HEIGHT INTEGER, CREATED_AT TEXT);',
    'CREATE UNIQUE INDEX IF NOT EXISTS MEDIA_ID ON MEDIA (ID);',
    'CREATE INDEX IF NOT EXISTS MEDIA_DATE ON MEDIA (CREATED_AT);',
    'CREATE TABLE IF NOT EXISTS FOLLOWERS(ID TEXT, TYPE TEXT, STATUS TEXT, AVATAR TEXT, NAME TEXT, CREATED_AT TEXT, FOLLOWED_AT TEXT);',
    'CREATE UNIQUE INDEX IF NOT EXISTS FOLLOWER_ID ON FOLLOWERS (ID);',
    'CREATE INDEX IF NOT EXISTS FOLLOWER_DATE ON FOLLOWERS (FOLLOWED_AT);',
].each { |sql| db.execute(sql) }

class Tweet < ActiveRecord::Base
end

class Media < ActiveRecord::Base
end

class Follower < ActiveRecord::Base
end

Tweet.establish_connection(
    :adapter => 'sqlite3',
    :database => db_path
)

Media.establish_connection(
    :adapter => 'sqlite3',
    :database => db_path
)

Follower.establish_connection(
    :adapter => 'sqlite3',
    :database => db_path
)


###########################################################################
# Utilities.
###########################################################################

$size_cache = {}

def image_size(uri)
  if !$size_cache.key?(uri)
    $size_cache[uri] = FastImage.size(uri)
  end
  return $size_cache[uri]
end

def get_tweet_text(tweet)
  final_text = tweet.text
  if tweet.media?
    media = tweet.media.first
    if media.kind_of? Twitter::Media::Photo
      media_size = image_size("#{media.media_uri}")
      if !media_size.nil?
        width = media_size[0]
        height = media_size[1]
        if height > 250
          width = (width * (250 / height.to_f)).to_i
          height = 250
        end
        final_text = final_text.sub(media.uri, "<div class=\"tweet-image\"><img width=\"#{width}\" height=\"#{height}\" src=\"#{media.media_uri}\" /></div>")
      end
    else
      tweet.media.each { |media|
        expanded_uri = "#{media.expanded_uri}"
        if (expanded_uri.size < 50)
          final_text = final_text.sub(media.uri, expanded_uri)
        end
      }
    end
  end
  if tweet.uris?
    tweet.uris.each { |uri|
      expanded_uri = "#{uri.expanded_uri}"
      if (expanded_uri.size < 50)
        final_text = final_text.sub(uri.uri, expanded_uri)
      end
    }
  end
  return final_text
end


###########################################################################
# Job's schedules.
###########################################################################

# Save Twitter query result in the database and send it to dashboard.
###########################################################################
SCHEDULER.every '1m', :first_in => 0 do |job|
  begin

    # Perform Twitter search for most recent tweets.
    tweets = twitter.search("#{search_query}", { :result_type => 'recent', :count => 100 })

    # Save all tweets in the database for later query.
    if tweets
      tweets.each do |tweet|
        if !Tweet.exists?(id: tweet.id)
          t            = Tweet.new
          t.ID         = tweet.id
          t.CREATED_AT = tweet.created_at.in_time_zone('Europe/Riga').iso8601
          t.CONTENT    = tweet.text
          t.AVATAR     = "#{tweet.user.profile_image_url_https}"
          t.NAME       = tweet.user.name
          t.save
          if tweet.media?
            tweet.media.each_with_index do |media, index|
              media_id       = "#{tweet.id}_#{index}"
              if !Media.exists?(id: media_id)
                m             = Media.new
                m.ID          = media_id
                m.CREATED_AT  = tweet.created_at.in_time_zone('Europe/Riga').iso8601
                m.SHORT_URI   = media.uri
                m.URI         = media.media_uri
                media_size    = FastImage.size("#{media.media_uri}")
                if !media_size.nil?
                  m.WIDTH     = media_size[0]
                  m.HEIGHT    = media_size[1]
                end
                m.save
              end
            end
          end
        end
      end
    end

    # Send most recent 18 tweets (excluding retweets) to dashboard.
    if tweets
      tweets = tweets.select { |tweet| !tweet.text.start_with?('RT') && !tweet.user.name.downcase.include?('poop') && !get_tweet_text(tweet).include?('ow.ly/lPlX30bg') }.take(18).map do |tweet|
        {
            name:      tweet.user.name,
            avatar:    "#{tweet.user.profile_image_url_https}",
            time:      tweet.created_at.in_time_zone('Europe/Riga').strftime("%m-%d %H:%M:%S"),
            body:      get_tweet_text(tweet),
            image:     tweet.media? ? tweet.media.first.media_uri : nil
        }
      end
      send_event('twitter_mentions', tweets: tweets.sort { |a, b| b[:time] <=> a[:time] })
    end

  rescue Twitter::Error => e
    puts "\e[33mError message: #{e.message}\e[0m"
  end
end


# Save Twitter followers in the database.
###########################################################################
SCHEDULER.every '1h', :first_in => 0 do |job|
  begin

    # Query Twitter for followers.
    accounts.each do |account|
      followers = twitter.followers(account, { :skip_status => false, :include_user_entities => true })
      if followers
        # Save all followers in the database for later query.
        followers.each do |follower|
          unless Follower.exists?(id: follower.id)
            f             = Follower.new
            f.ID          = follower.id
            f.CREATED_AT  = follower.created_at.in_time_zone('Europe/Riga').iso8601
            f.FOLLOWED_AT = Time.now.in_time_zone('Europe/Riga').iso8601
            f.AVATAR      = "#{follower.profile_image_url_https}"
            f.NAME        = follower.name
            f.TYPE        = "twitter#{account}"
            f.STATUS      = 'active'
            f.save
          end
        end
      end
    end

  rescue Twitter::Error => e
    puts "\e[33mError message: #{e.message}\e[0m"
  end
end


# Select Twitter statistics from the database.
###########################################################################
SCHEDULER.every '1m', :first_in => 0 do |job|
  begin

    # Select number of tweets posted per hour for last 10 hours and send it to dashboard.
    activity = []
    i = 10
    db.execute( "select count(*), strftime('%Y-%m-%d %H:00', created_at) from tweets group by 2 order by 2 desc limit 10;" ) do |row|
      activity << {
        x: i,
        y: row[0]
      }
      i -= 1
    end
    activity = activity.sort { |a, b| a[:x] <=> b[:x] }
    if !activity.empty?
      send_event('twitter_activity', { graphtype: 'bar', points: activity })
    end

  rescue Exception => e
    puts "\e[33mError message: #{e.message}\e[0m"
  end
end


# Select top Twitter posters from the database.
###########################################################################
SCHEDULER.every '1m', :first_in => 0 do |job|
  begin

    # Select top users that posted tweets within last 3 hours and send it to dashboard.
    top_users = []
    query_time = Time.now.in_time_zone('Europe/Riga').advance(:hours => -12).iso8601
    db.execute( "select count(*), name, avatar from tweets where datetime(created_at) > datetime(?) and name not like '%Poop%' and content not like 'RT%' group by 2, 3 order by 1 desc, 2 asc;", [query_time] ) do |row|
      top_users << {
        name: row[1],
        avatar: row[2],
        tweet_count: row[0]
      }
    end
    unless top_users.empty?
      send_event('twitter_top_users', {users: top_users.take(6)})
    end

  rescue Exception => e
    puts "\e[33mError message: #{e.message}\e[0m"
  end
end

