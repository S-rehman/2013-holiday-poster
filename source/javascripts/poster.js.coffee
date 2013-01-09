class Poster
  constructor: (options) ->
    {
      @noise, @gravity, @step_size, @friction,
      @radius_min, @radius_max
    } = options

    # @nodes = @nodes_from_noise()
    @nodes = []

    pack = (a, b, c) ->
      db = a.r + c.r
      dx = b.x - a.x
      dy = b.y - a.y

      if (db && (dx || dy))
        da = b.r + c.r
        dc = dx * dx + dy * dy

        da *= da
        db *= db

        x = 0.5 + (db - da) / (2 * dc)
        y = Math.sqrt(Math.max(0, 2 * da * (db + dc) - (db -= dc) * db - da * da)) / (2 * dc)

        c.x = a.x + x * dx + y * dy
        c.y = a.y + x * dy - y * dx
      else
        c.x = a.x + db
        c.y = a.y

    q = d3.geom.quadtree(@nodes)
    queue = []

    # start with a random point
    x = Math.random() * @w()
    y = Math.random() * @h()
    n0 = { x: x, y: y, r: @r_for_point(x, y), i: 0 } 
    @nodes.push n0
    queue.push n0

    n1 = { r: @r_for_point(n0.x + n0.r, n0.y), i: 1 }
    n1.x = n0.x + n0.r + n1.r
    n1.y = y
    @nodes.push n1 
    queue.push n1

    node_id = 2
    while (node = queue.shift())
      temp_nodes = []
      for i in [0...8]
        new_node = { r: @radius_min }
        if i is 0
          placement_node = if node.i is 0 then @nodes[1] else @nodes[node.i - 1]
        else
          placement_node = temp_nodes[i - 1]

        # Walk towards optimal size/fit
        while true
          pack(node, placement_node, new_node)
          if (@r_for_point(new_node.x, new_node.y) > new_node.r)
            new_node.r += 1
          else
            break
        temp_nodes.push(new_node)
        for candidate_node in temp_nodes
          unless @should_cull(candidate_node)
            candidate_node.i = node_id++
            queue.push(candidate_node)
            @nodes.push(candidate_node)


    # i = 2
    # collision = false
    # while !collision
      # nx = { r: 5, color: "blue" }
      # while true
        # pack(n0, @nodes[i-1], nx)
        # if (@r_for_point(nx.x, nx.y) > nx.r)
          # console.log("r for point: #{@r_for_point(nx.x, nx.y)}")
          # nx.r += 1
        # else
          # break
      # # console.log("collision #{i}") if @collides(nx, @nodes)
      # collision = @collides(nx, @nodes)
      # unless collision
        # @nodes.push nx
        # i++

    # for n0, idx in @nodes[1..]
      # i = idx + 1
      # collision = false
      # while !collision
        # nx = { r: 5, color: "red" }
        # # Walk towards optimal size/fit
        # while true
          # pack(n0, @nodes[i-1], nx)
          # if (@r_for_point(nx.x, nx.y) > nx.r)
            # nx.r += 1
          # else
            # break
        # # console.log("collision #{i}") if @collides(nx, @nodes)
        # collision = @collides(nx, @nodes)
        # unless collision
          # @nodes.push nx
          # i++

    # console.log n.r for n in @nodes

    # @nodes.push { r: radius } for radius in [5..30] by 5
    # pack(n0, n1, node) for node in @nodes[2..]

    # console.log node.r for node in @nodes

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

    @force.on "tick", (e) =>
      q = d3.geom.quadtree(@nodes)
      q.visit @collide(node) for node in @nodes

      @svg.selectAll("circle")
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)

  collides: (node, nodes) ->
    for point in nodes
      x = node.x - point.x
      y = node.y - point.y
      l = Math.sqrt(x*x + y*y)
      r = node.r + point.r
      if (r - l) > 0.001
        return true

  should_cull: (node) ->
    {x, y, r} = node
    x + r < -100 ||
    y + r < -100 ||
    x - r > @w() + 100 ||
    y - r > @h() + 100 ||
    @collides(node, @nodes)

  r_for_point: (x, y) ->
    @noise.for_point(x, y) * (@radius_max - @radius_min) + @radius_min

  w: () ->
    window.innerWidth

  h: () ->
    window.innerHeight

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
    # @force.tick() for [1..150]
    # @force.stop()
    # @circles
        # .sort( (a, b) => 
          # mx = @w() / 2
          # my = @h() / 2
          # 10*(b.r - a.r) + (@dist(a.x, a.y, mx, my) - @dist(b.x, b.y, mx, my)) )
        # .transition()
        # .delay( (d, i) -> i * 2)
        # .duration(400)
        # .attr("stroke-opacity", 1)

  collide: (node) ->
      r = node.r
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
            l = (l - r) / l * .75
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
# window.nc = new Poster.NoiseCanvas noise: window.n, opacity: 0.5
window.poster = new Poster {
  noise: window.n
  gravity: 0.01
  friction: 0.4
  step_size: 20
  radius_min: 5
  radius_max: 30
}
window.poster.draw()
