class Circle
  constructor: ({@r, @cx, @cy}) ->
    @[p] = (Math.round v) for own p, v of @
    @opacity = 0.3
    @base_opacity = 0.3
    @max_opacity = Math.min(0.3 + (@r-5/25) * 0.7, 1)

  draw: (ctx) ->
    ctx.beginPath()
    ctx.arc(@cx, @cy, @r, 0, Math.PI*2)
    # ctx.fill()
    ctx.strokeStyle = @stroke_style()
    # ctx.globalAlpha = @opacity
    ctx.stroke()

  stroke_style: () ->
    [h1, s1, l1] = Circle.fill_colors
    [h2, s2, l2] = Circle.stroke_colors

    adjusted_opacity = @opacity - @base_opacity

    r = (Math.random() - 0.5) * 5
    rl = (Math.random() - 0.5) * 7
    r *= adjusted_opacity
    rl *= adjusted_opacity

    highlighted = Circle.interp [h2, s2, l2],
                                Circle.highlight_colors,
                                adjusted_opacity
    highlighted[0] += r
    highlighted[1] += rl
    highlighted[2] += rl

    Circle.a2hsl(Circle.interp Circle.fill_colors, highlighted, @opacity)


  # Class vars

  @fill_colors:      [31,12,58] # All values HSL
  @stroke_colors:    [30,12,69]
  @highlight_colors: [30,50,69]
  @line_width: 2.5

  # Class methods

  @a2rgb: (a) ->
    "rgb(#{a.join()})"

  @a2hsl: (a) ->
    [h, s, l] = a
    s = Math.round(a[1]*10) / 10
    l = Math.round(a[2]*10) / 10
    "hsl(#{h}, #{s}%, #{l}%)"

  # c.f. https://github.com/mbostock/d3/blob/master/src/core/interpolate.js
  @interp: (a1, a2, k) ->
    h0 = a1[0]
    s0 = a1[1]
    l0 = a1[2]
    h1 = a2[0] - h0
    s1 = a2[1] - s0
    l1 = a2[2] - l0

    # ensure shortest path
    if (h1 > 180)
      h1 -= 360
    else if (h1 < -180)
      h1 += 360

    [
      h0 + k * h1
      s0 + k * s1
      l0 + k * l1
    ]

  @setup_context: (ctx) ->
    ctx.strokeStyle = @a2hsl @stroke_colors
    ctx.fillStyle   = @a2hsl @fill_colors
    ctx.lineWidth   = @line_width

  @randomize_tint: () ->
    hue = Math.round(Math.random() * 360)
    @highlight_colors[0] = hue
    console.log("Starting hue: #{hue}")

  @drift_tint: () ->
    skew = (Math.random() - 0.5) * 10
    hue = @highlight_colors[0]
    adjusted_hue = hue + skew

    # Stay away from the 180º boundary to avoid drastic hue shifts.
    # I thought the d3 interpolation function would keep this from happening, 
    # but I was wrong. I don't understand color spaces very well!
    if 208 < adjusted_hue < 211
      adjusted_hue = hue - skew

    @highlight_colors[0] = if adjusted_hue > 0
        adjusted_hue % 360
      else
        adjusted_hue + 360

# exports
window.Circle = Circle
