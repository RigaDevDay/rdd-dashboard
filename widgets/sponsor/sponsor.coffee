class Dashing.Sponsor extends Dashing.Widget

  ready: ->
    container = $(@node).parent()
    @sponsors = container.data("sponsors").split ' '
    @currentIndex = 0
    @sponsorElem = $(@node).find('.sponsor-container')
    @nextSponsor()
    @startCarousel()

  startCarousel: ->
    setInterval(@nextSponsor, 8000)

  nextSponsor: =>
    @sponsorElem.fadeOut =>
      @currentIndex = (@currentIndex + 1) % @sponsors.length
      @set 'current_sponsor', @sponsors[@currentIndex]
      @sponsorElem.fadeIn()
