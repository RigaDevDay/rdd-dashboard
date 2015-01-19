class Dashing.Schedule extends Dashing.Widget

  @accessor 'quote', ->
    "“#{@get('current_session')?.body}”"

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
    if comments
      @sessionElem.fadeOut =>
        @currentIndex = (@currentIndex + 1) % sessions.length
        @set 'current_sessions', sessions[@currentIndex]
        @sessionElem.fadeIn()
