class Poster
  constructor: (options) ->
    {@noise, @gravity, @step_size, @friction} = options

    @nodes = @nodes_from_noise()

    @svg = d3.select(document.body).append("svg:svg")
      .attr("width", @w())
      .attr("height", @h())

    @force = d3.layout.force()
      .nodes(@nodes)
      .links([])
      .gravity(@gravity)
      .friction(@friction)
      .charge(0)
      .size([@w(), @h()])

    @circles = @svg.selectAll("circle")
        .data(@nodes)
      .enter().append("svg:circle")
        .attr("r", (d) -> d.r)
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)
        .attr("fill", "none")
        .attr("stroke", "#b9afa5")
        .attr("stroke-opacity", 0)
        .attr("stroke-width", 3)

    @force.on "tick", (e) =>
      q = d3.geom.quadtree(@nodes)
      q.visit @collide(node) for node in @nodes

      @svg.selectAll("circle")
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)

  w: () ->
    window.innerWidth

  h: () ->
    window.innerHeight

  # charge: (d) ->
    # Math.pow(d.r, 2.0) / 8

  nodes_from_noise: () ->
    nodes = []
    w = @w()
    h = @h()
    for y in [0...h] by @step_size
      for x in [0...w] by @step_size
        n = @noise.for_point(x, y)
        nodes.push {
          x: x
          y: y
          r: n * 30 + 5
          scale: n
        } if Math.random() > n
    nodes

  dist: (x1, y1, x2, y2) ->
    dx = x2 - x1
    dy = y2 - y1
    Math.sqrt(dx*dx + dy*dy)

  draw: () ->
    @force.start()
    @force.tick() for [1..150]
    @force.stop()
    @circles
        .sort( (a, b) => 
          mx = @w() / 2
          my = @h() / 2
          10*(b.r - a.r) + (@dist(a.x, a.y, mx, my) - @dist(b.x, b.y, mx, my)) )
        .transition()
        .delay( (d, i) -> i * 2)
        .duration(400)
        .attr("stroke-opacity", 1)

  collide: (node) ->
      r = node.r + 16
      nx1 = node.x - r
      nx2 = node.x + r
      ny1 = node.y - r
      ny2 = node.y + r

      return (quad, x1, y1, x2, y2) ->
        if (quad.point && (quad.point != node)) 
          x = node.x - quad.point.x
          y = node.y - quad.point.y
          l = Math.sqrt(x * x + y * y)
          r = node.r + quad.point.r
          if (l < r) 
            l = (l - r) / l * .5
            node.x -= x *= l
            node.y -= y *= l
            quad.point.x += x
            quad.point.y += y
        
        (x1 > nx2) || (x2 < nx1) || (y1 > ny2) || (y2 < ny1)

class Poster.Noise
  constructor: (@scale) ->
    @simplex = new SimplexNoise

  for_point: (x, y) ->
    x = x / @scale
    y = y / @scale

    @simplex.noise2D(x, y) * 0.5 + 0.5 # translate from -1-1 to 0-1


class Poster.NoiseCanvas
  constructor: (options) ->
    {@noise, @opacity} = options
    @opacity *= 255 # convert from 0-1 to 0-255
    @canvas = d3.select(document.body).append("canvas").node()
    @ctx = @canvas.getContext("2d")

    window.addEventListener("resize", _.debounce(@draw, 0), false)
    @draw()

  draw: =>
    w = @canvas.width = window.innerWidth
    h = @canvas.height = window.innerHeight
    image_data = @ctx.getImageData(0, 0, w, h)
    data = image_data.data

    for y in [0...h]
      for x in [0...w]
        yOff = y * w * 4
        xOff = x * 4
        c = Math.round(@noise.for_point(x, y) * 255)
        data[yOff + xOff + 0] = c
        data[yOff + xOff + 1] = c
        data[yOff + xOff + 2] = c
        data[yOff + xOff + 3] = @opacity

    @ctx.putImageData(image_data, 0, 0)

window.n = new Poster.Noise 256
# window.nc = new Poster.NoiseCanvas noise: window.n, opacity: 0.1
window.poster = new Poster noise: window.n, gravity: 0.01, friction: 0.4, step_size: 20
window.poster.draw()
