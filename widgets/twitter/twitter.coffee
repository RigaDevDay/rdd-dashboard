class Dashing.Twitter extends Dashing.Widget

  ready: ->
    @currentIndex = 0
    @commentElem = $(@node).find('.comment-container')
    @nextComment()
    @startCarousel()

  onData: (data) ->
    @currentIndex = 0

  startCarousel: ->
    setInterval(@nextComment, 8000)

  nextComment: =>
    comments = @get('comments')
    if comments
      @commentElem.fadeOut =>
        @currentIndex = (@currentIndex + 1) % comments.length
        @set 'visible_comments', comments.slice(@currentIndex, @currentIndex + 2)
        @commentElem.fadeIn()
