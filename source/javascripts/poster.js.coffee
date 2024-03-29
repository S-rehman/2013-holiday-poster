#= require circle

class Poster
  constructor: (options) ->
    {
      @json_url
    } = options

    @w = @width()
    @h = @height()

    @glimmer_distance = 1
    @glimmer_target = 0

    @canvas = ($ "<canvas></canvas>").appendTo(document.body)
      .attr("width", @w)
      .attr("height", @h)

    @ctx = @canvas.get(0).getContext("2d")
    Circle.setup_context(@ctx)

    ($ window).resize(() =>
      @w = @width()
      @h = @height()
      @position_heading()
      @canvas
        .attr("width", @w)
        .attr("height", @h)
      @build_circles() if @data?
    )

    ($ document).on "keypress", (e) =>
      return unless e.which is 32 # space bar
      if @raf?
        @stop()
        (console.log "pause")
      else
        @animate()
        (console.log "unpause")

    $.getJSON @json_url, (data) =>
      that = @
      @data = data
      @build_circles()

      count = @circles.length
      counter = 0
      for c in @circles
        do (c) ->
          delay = Math.max((20 / c.r) * 800 - 800, 0)
          c.opacity = 0
          c.tween = new TWEEN.Tween(o: 0)
            .to({ o: 0.3 }, 1500)
            .delay(delay)
            .easing(TWEEN.Easing.Quadratic.InOut)
            .onUpdate(() ->
              c.opacity = @o)
            .start()
      @animate()

      _.delay((() =>
        @init_text()
      ), 600)

      _.delay((() =>
        @update_glimmer = @glimmer
      ), 2400)

  build_circles: () ->
    Circle.setup_context(@ctx)
    @circles =
      for d in @data when +d.cx < @w + 30 and +d.cy < @h + 30
        new Circle(d)

  animate: () =>
    @raf = requestAnimationFrame @animate
    @tick()

  stop: () ->
    cancelAnimationFrame @raf
    @raf = null

  tick: () ->
    if @freeze_circles
      @stop()
    else
      # console.time("draw")
      TWEEN.update()
      @update_glimmer() if @update_glimmer?
      @ctx.clearRect(0, 0, @w, @h)
      c.draw(@ctx) for c in @circles
      # console.timeEnd("draw")

  init_text: () ->
    @heading = ($ "h1")
    @chars = @heading
        .lettering("lines")
      .children()
        .addClass("line")
        .lettering("words")
      .children()
        .addClass("word")
        .lettering()
      .children()
        .addClass("char")

    @position_heading()
      .css("visibility", "visible")

    interval = 800
    delay = -interval

    spans = @heading.find(".word")
      .css("opacity", 0)
      .each (i, el) ->
        el = $(el)
        text = el.text()

        if (text.toLowerCase() in ["fun", "to", "impossible."])
          delay += interval * 2
        else
          delay += interval

        el.delay(delay)
          .animate({ opacity: 1 }, 2000)

    ($ "footer")
      .delay(9000)
      .animate({
        opacity: 1
      }, 2000)

  position_heading: () =>
    h = @h
    @heading
      .css("top", () -> "#{(h - @clientHeight) / 2}px" )

  glimmer: () =>
    # The distance is where the current "crest" of the wave is.
    #
    # The target is the point on the other side of the screen we're
    # driving towards.
    if @glimmer_distance > @glimmer_target
      @init_glimmer()

    @glimmer_v *= @glimmer_accel
    @glimmer_distance += @glimmer_v

    # These steps represent how far from @glimmer_distance the bubbles
    # should start to brighten, fade out to almost nothing, and then
    # fade back to default brightness.
    #
    # In the declarative version, these were set as animation durations,
    # not distances-from-the-crest. Here, they're precalcuated distances
    # based on screen size.
    s1 = @glimmer_step1
    s2 = @glimmer_step2
    s3 = @glimmer_step3

    @canvas.trigger "glimmer", @glimmer_distance

    Circle.drift_tint()
    Circle.highlight_colors[1] = @tween_glimmer @glimmer_distance,
                                                12,
                                                25,
                                                @glimmer_target - s3

    for c in @circles
      cd = @dist(c.cx, c.cy, @glimmer_cx, @glimmer_cy)
      delta = cd - @glimmer_distance

      # Determine which stage of the animation we're in and
      # tween accordingly:

      # Brighten to max
      if (0 < delta < s1)
        c.opacity = @tween_glimmer(s1-delta, 0.3, c.max_opacity, s1)
      # Fade to min
      else if (-s2 < delta < 0)
        c.opacity = @tween_glimmer(s2+delta, 0.1, c.max_opacity, s2)
      # Return to base opacity
      else if (-(s2+s3) < delta < -s2)
        c.opacity = @tween_glimmer(-delta-s2, 0.1, 0.3, s3)
      # Nowhere near the crest of the wave
      else
        c.opacity = c.base_opacity

    for char, i in @chars
      char = @chars.eq(i)
      offset = char.offset()
      cd = @dist(offset.left, offset.top, @glimmer_cx, @glimmer_cy)
      delta = cd - @glimmer_distance
      if (0 < delta < s1)
        text_shadow = @tween_glimmer(s1-delta, 0, 30, s1)
      else if (-s2 < delta < 0)
        text_shadow = @tween_glimmer(s2+delta, 0, 30, s2)
      else if (-(s2+s3) < delta < -s2)
        text_shadow = 0
      else
        text_shadow = 0
      char.css("text-shadow", "0 0 #{text_shadow}px hsl(#{Circle.highlight_colors[0]}, 100%, 94%)")

    return undefined

  # c.f. http://upshots.org/actionscript/jsas-understanding-easing
  tween_glimmer: (t, b, e, d) ->
    elapsed = t / d
    elapsed = 1 if elapsed > 1
    value = TWEEN.Easing.Quadratic.InOut(elapsed)
    b + ( e - b ) * value

  init_glimmer: () ->
    @glimmer_count ?= -1
    ++@glimmer_count

    if @glimmer_count > 1
      Circle.randomize_tint()

    cx = parseInt Math.random() * @w
    cy = parseInt Math.random() * @h

    hx = @w/2
    hy = @h/2

    if Math.random() > 0.5
      if Math.random() > 0.5 then cx = 0 else cx = @w
    else
      if Math.random() > 0.5 then cy = 0 else cy = @h

    if @glimmer_count is 0
      cx = hx
      cy = 0

    if cx > hx then destx = 0 else destx = @w
    if cy > hy then desty = 0 else desty = @h

    longest_side = if @w > @h then @w else @h

    @glimmer_cx = cx
    @glimmer_cy = cy
    @glimmer_step1 =  Math.max(Math.round(longest_side/3), 400)
    @glimmer_step2 = @glimmer_step1 * 1.5
    @glimmer_step3 = @glimmer_step2 * 2
    @glimmer_target = @dist(cx, cy, destx, desty) + @glimmer_step3
    @glimmer_distance = -@glimmer_step1
    @glimmer_v = 3
    @glimmer_accel = 1.01

  width: () ->
    window.innerWidth

  height: () ->
    window.innerHeight

  dist: (x1, y1, x2, y2) ->
    dx = x2 - x1
    dy = y2 - y1
    Math.sqrt(dx*dx + dy*dy)

window.poster = new Poster {
  json_url: "/data/bubbles-#{Math.round(Math.random() * 10)}.json"
}

