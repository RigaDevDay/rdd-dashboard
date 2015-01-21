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
        @set 'visible_comments', comments.slice(@currentIndex, @currentIndex + 3).concat(comments.slice(0, Math.max(0, @currentIndex + 3 - comments.length)))
        @currentIndex = (@currentIndex + 3) % comments.length
        @commentElem.fadeIn()
