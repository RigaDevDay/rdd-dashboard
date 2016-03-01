class Dashing.Heroes extends Dashing.Widget
  ready: ->
    @herosElem = $(@node).find('.hero-container')
    @herosElem.fadeOut =>
      @herosElem.fadeIn()
