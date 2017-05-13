
require 'yaml'
require 'uri'
require 'net/http'
require 'json'

###########################################################################
# Climate icon mapping to Yahoo weather codes.
###########################################################################

climacon_class_to_code = {
    'cloud'            => [26, 44],
    'cloud moon'       => [27, 29],
    'cloud sun'        => [28, 30],
    'drizzle'          => [8, 9],
    'fog'              => [20],
    'hail'             => [17, 35],
    'haze'             => [19, 21, 22],
    'lightning'        => [3, 4, 37, 38, 39, 45, 47],
    'moon'             => [31, 33],
    'rain'             => [11, 12, 40],
    'sleet'            => [6, 10, 18],
    'snow'             => [5, 7, 13, 14, 15, 16, 41, 42, 43, 46],
    'sun'              => [32, 34],
    'thermometer full' => [36],
    'thermometer low'  => [25],
    'tornado'          => [0, 1, 2],
    'wind'             => [23, 24],
}

def climacon_class(climacon_class_to_code, weather_code)
  climacon_class_to_code.select{ |k, v| v.include? weather_code.to_i }.to_a.first.first
end


###########################################################################
# Job's body.
###########################################################################

SCHEDULER.every '5m', :first_in => 0 do |job|

  url = [
      "http://query.yahooapis.com/v1/public/yql?",
      "&q=select * from weather.forecast where woeid in (",
      " select woeid from geo.places(1) where text=\"riga\"",
      " )",
      "&format=json",
      "&env=store://datatables.org/alltableswithkeys"
  ].join("")

  url = URI.escape(url)
  uri = URI.parse(url)

  puts "Fetching weather from: #{uri}"

  response = Net::HTTP.get_response(uri)

  begin

    json = JSON.parse(response.body)

    if json['query'] && json['query']['results'] && json['query']['results']['channel']

      channel = json['query']['results']['channel']
      weather_data = channel['item']['condition']
      weather_location = channel['location']
      temp_fahrenheit = weather_data['temp']
      temp_celsius = ((temp_fahrenheit.to_f - 32) * 5/9).to_i

      send_event('weather', {
          temp:      "#{temp_celsius}&deg;C",
          condition: weather_data['text'],
          title:     "#{weather_location['city']} Weather",
          climacon:  climacon_class(climacon_class_to_code, weather_data['code'])
      })

    end

  rescue Exception => e
    puts "\e[33mError message: #{e.message}\e[0m"
  end

end