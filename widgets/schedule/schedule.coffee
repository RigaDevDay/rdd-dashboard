class Dashing.Schedule extends Dashing.Widget

  ready: ->
    @currentIndex = 0
    @sessionElem = $(@node).find('.session-container')
    @nextSession()
    @startCarousel()

  onData: (data) ->
    @currentIndex = 0

  startCarousel: ->
    setInterval(@nextSession, 8000)

  nextSession: =>
    sessions = @get('sessions')
    if sessions
      @sessionElem.fadeOut =>
        @currentIndex = (@currentIndex + 1) % sessions.length
        @set 'current_session', sessions[@currentIndex]
        @sessionElem.fadeIn()
