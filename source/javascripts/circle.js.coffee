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
    [r1, g1, b1] = Circle.fill_colors
    [r2, g2, b2] = Circle.stroke_colors
    Circle.a2rgb [
      Math.floor r1 + @opacity * (r2 - r1)
      Math.floor g1 + @opacity * (g2 - g1)
      Math.floor b1 + @opacity * (b2 - b1)
    ]


  # Class vars
  @fill_colors: [160, 148, 135]
  @stroke_colors: [185, 175, 165]
  @line_width: 2.5

  # Class methods
  @a2rgb: (a) ->
    "rgb(#{a.join()})"

  @setup_context: (ctx) ->
    ctx.strokeStyle = @a2rgb @stroke_colors
    ctx.fillStyle   = @a2rgb @fill_colors
    ctx.lineWidth   = @line_width


# exports
window.Circle = Circle
