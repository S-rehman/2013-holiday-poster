#= require circle

class Poster
  constructor: (options) ->
    {
      @json_url
    } = options

    @w = @width()
    @h = @height()

    # @init_text()
    @glimmer_distance = 1
    @glimmer_target = 0

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

      # count = @circles.length
      # counter = 0
      # for c in @circles
        # do (c) ->
          # duration = Math.min((20 / c.r) * 8000, 10000)
          # c.opacity = 0
          # c.tween = new TWEEN.Tween(o: 0)
            # .to({ o: 0.4 }, duration)
            # .easing(TWEEN.Easing.Quadratic.InOut)
            # .onUpdate(() ->
              # c.opacity = @o)
            # .onComplete(() ->
              # if (++counter == count)
                # that.freeze_circles = true)
            # .start()
      @animate()
      _.delay((() => @update_glimmer = @glimmer), 100)

  animate: () =>
    @raf = requestAnimationFrame @animate
    @tick() unless @freeze_circles


  stop: () ->
    cancelAnimationFrame @raf

  tick: () ->
    # console.time("draw")
    # TWEEN.update()
    @update_glimmer() if @update_glimmer?
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
    if @glimmer_distance > @glimmer_target
      @init_glimmer()

    @glimmer_v *= @glimmer_accel
    @glimmer_distance += @glimmer_v

    s1 = @glimmer_step1
    s2 = @glimmer_step2
    s3 = @glimmer_step3

    for c in @circles
      cd = @dist(c.cx, c.cy, @glimmer_cx, @glimmer_cy)
      delta = cd - @glimmer_distance
      if (0 < delta < s1)
        c.opacity = @tween_glimmer(s1-delta, 0.4, c.max_opacity, s1)
      else if (-s2 < delta < 0)
        c.opacity = @tween_glimmer(s2+delta, 0.1, c.max_opacity, s2)
      else if (-(s2+s3) < delta < -s2)
        c.opacity = @tween_glimmer(-delta-s2, 0.1, 0.4, s3)
      else
        c.opacity = c.base_opacity
    return undefined

  tween_glimmer: (t, b, e, d) ->
    elapsed = t / d
    elapsed = 1 if elapsed > 1
    value = TWEEN.Easing.Quadratic.InOut(elapsed)
    b + ( e - b ) * value

  init_glimmer: () ->
    @glimmer_count ?= -1
    @glimmer_count++

    # if @glimmer_count++ > 10
      # @freeze_circles = true
      # return

    # @freeze_circles = false

    # tween_duration = 1000

    cx = parseInt Math.random() * @w
    cy = parseInt Math.random() * @h

    hx = @w/2
    hy = @h/2

    if Math.random() > 0.5
      if Math.random() > 0.5 then cx = 0 else cx = @w
    else
      if Math.random() > 0.5 then cy = 0 else cy = @h

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
  json_url: "/javascripts/bubbles.json"
}

