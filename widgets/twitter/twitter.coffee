class Dashing.Twitter extends Dashing.Widget

  ready: ->
    @currentIndex = 0
    @tweetElem = $(@node).find('.tweet-container')
    @nextTweet()
    @startCarousel()

  onData: (data) ->
    @currentIndex = 0

  startCarousel: ->
    setInterval(@nextTweet, 10000)

  nextTweet: =>
    tweets = @get('tweets')
    if tweets
      @tweetElem.fadeOut =>
        selectedTweets = []
        wallLength = 0
        while true
          currentTweet = tweets[@currentIndex]
          if currentTweet.image
            wallLength += 2
          else
            wallLength += 1        
          if wallLength <= 3
            selectedTweets.push currentTweet
            @currentIndex = (@currentIndex + 1) % tweets.length
          else 
            break
        @set 'visible_tweets', selectedTweets
        @tweetElem.fadeIn()
