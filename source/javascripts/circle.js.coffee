class Circle
  constructor: ({@r, @cx, @cy}) ->
    @[p] = (Math.round v) for own p, v of @
    @opacity = 0.4
    @base_opacity = 0.4
    @max_opacity = Math.min(0.4 + (@r-5/25) * 0.6, 1)

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

  @interp: (a1, a2, k) ->
    [
      a1[0] + k * (a2[0] - a1[0])
      a1[1] + k * (a2[1] - a1[1])
      a1[2] + k * (a2[2] - a1[2])
    ]

  @setup_context: (ctx) ->
    ctx.strokeStyle = @a2hsl @stroke_colors
    ctx.fillStyle   = @a2hsl @fill_colors
    ctx.lineWidth   = @line_width

  @randomize_tint: () ->
    skew = (Math.random() - 0.5) * 10
    hue = @highlight_colors[0]
    @highlight_colors[0] = Math.abs(hue + skew) % 360


# exports
window.Circle = Circle
