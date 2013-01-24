#= require circle

class Poster
  constructor: (options) ->
    {
      @json_url
    } = options

    @w = @width()
    @h = @height()

    # @init_text()

    @canvas = ($ "<canvas></canvas>").appendTo(document.body)
      .attr("width", @w)
      .attr("height", @h)

    @ctx = @canvas.get(0).getContext("2d")
    Circle.setup_context(@ctx)

    $.getJSON @json_url, (data) =>
      that = @
      @circles = 
        for d in data when +d.cx < @w and +d.cy < @h
          new Circle(d)
      
      count = @circles.length
      counter = 0
      for c in @circles
        do (c) ->
          duration = Math.min((20 / c.r) * 8000, 10000)
          c.opacity = 0
          c.tween = new TWEEN.Tween(o: 0)
            .to({ o: 0.4 }, duration)
            .easing(TWEEN.Easing.Quadratic.InOut)
            .onUpdate(() ->
              c.opacity = @o)
            .onComplete(() -> 
              if (++counter == count)
                that.freeze_circles = true)
            .start()
      @animate()
      _.delay(@glimmer, 10000)

  animate: () =>
    @raf = requestAnimationFrame @animate
    TWEEN.update()
    @draw() unless @freeze_circles
    

  stop: () ->
    cancelAnimationFrame @raf

  draw: () ->
    # console.time("draw")
    @ctx.clearRect(0, 0, @w, @h)
    c.draw(@ctx) for c in @circles
    # console.timeEnd("draw")

  init_text: () ->
    h = @h
    delay_for = 4000
    @heading = ($ "h1")
        .css("top", () -> "#{(h - @clientHeight) / 2}px" )
        .css("visibility", "visible")

    spans = @heading.find("span")
      .css("opacity", 0)
    
    new TWEEN.Tween(o: 0)
      .to({o: 1}, 1500)
      .delay(delay_for)
      .onUpdate(() -> spans.css("opacity", @o))
      .start()

    # _.delay( () =>
      # @heading.selectAll("span")
        # .transition()
          # .duration(1500)
          # .delay( (d, i) -> 1500 * i )
          # .style("opacity", 1)
    # , delay_for)

    # _.delay( ()=>
      # d3.select("footer")
        # .transition()
        # .duration(1500)
        # .style("opacity", 1)
    # , delay_for + 1500*4)


  glimmer: () =>
    @glimmer_count ?= 0

    if @glimmer_count++ > 10
      @freeze_circles = true
      return

    @freeze_circles = false

    tween_duration = 1000

    cx = parseInt Math.random() * @w
    cy = parseInt Math.random() * @h

    if Math.random() > 0.5
      if Math.random() > 0.5 then cx = 0 else cx = @w
    else
      if Math.random() > 0.5 then cy = 0 else cy = @h

    for c in @circles
      do (c) ->
        opacity = 0.4 + (c.r/30) * 0.6
        d1 = c.cx - cx
        d2 = c.cy - cy
        delay = Math.sqrt(d1*d1 + d2*d2)

        c.tween.stop()

        update = () ->
          c.opacity = @opacity

        tween_in = new TWEEN.Tween(opacity: 0.4)
          .to({ opacity: opacity }, tween_duration)
          .easing(TWEEN.Easing.Quadratic.InOut)
          .delay(delay)
          .onUpdate update

        tween_out = new TWEEN.Tween(c)
          .to({ opacity: 0.1 }, tween_duration)
          .easing(TWEEN.Easing.Quadratic.InOut)
          .onUpdate update
            
        tween_back = new TWEEN.Tween(c)
          .to({ opacity: 0.4 }, tween_duration)
          .easing(TWEEN.Easing.Quadratic.InOut)
          .onUpdate update
            
        tween_in.chain(tween_out)
        tween_out.chain(tween_back)

        c.tween = tween_in.start()

    _.delay(@glimmer, (tween_duration*4) + Math.random() * 4000)
  
  width: () ->
    window.innerWidth

  height: () ->
    window.innerHeight

window.poster = new Poster {
  json_url: "/javascripts/bubbles.json"
}

