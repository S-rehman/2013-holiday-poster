class Poster
  constructor: (options) ->
    {
      @noise, @gravity, @step_size, @friction,
      @radius_min, @radius_max
      @padding
    } = options

    @svg = d3.select(document.body).append("svg:svg")
      .attr("width", @w())
      .attr("height", @h())
    
    @STEP = 100

    @nodes = []

    @queue = []

    @temp_nodes = []

    @rejects = []

    # start with a point in the middle
    x = Math.round(@w() / 2)
    y = Math.round(@h() / 2)
    angle = Math.PI / 4
    n0 = { x: x, y: y, r: @r_for_point(x, y), i: 0 }
    @nodes.push n0
    @queue.push n0

    @draw_circles()

    _.delay(@bubble_2, @STEP, x, y, angle, n0)
    
  bubble_2: (x, y, angle, n0) =>
    x = x + n0.r * Math.cos(angle)
    y = y + n0.r * Math.sin(angle)
    r = @r_for_point(x + n0.r, y)
    n1 = {
      r: r
      x: x + r * Math.cos(angle)
      y: y + r * Math.sin(angle)
      i: 1
    }
    @nodes.push n1
    @queue.push n1

    @node_id = 2
    @q = d3.geom.quadtree(@nodes,
                          -@padding,
                          -@padding,
                          @w() + @padding,
                          @h() + @padding)
    @draw_circles()

    _.delay(@place_next_nodes, @STEP)

  place_next_nodes: () =>
    if (@current_node = @queue.shift())
      @temp_nodes = []
      @temp_counter = 0
      @generate_placement_nodes()
  
  generate_placement_nodes: () =>
    node = @current_node
    if @temp_counter < 8
      new_node = { r: @radius_min }
      if @temp_counter is 0
        @placement_node = if node.i is 0 then @nodes[1] else @nodes[node.i - 1]
      else
        @placement_node = @temp_nodes[@temp_counter - 1]

      # Walk towards optimal size/fit
      while true
        @pack(node, @placement_node, new_node)
        if (@r_for_point(new_node.x, new_node.y) > new_node.r)
          new_node.r += 1
        else
          break
      @temp_nodes.push(new_node)
      @draw_circles()
      @temp_counter++
      _.delay @generate_placement_nodes, @STEP
    else
      _.delay @cull_candidates, @STEP
   
  cull_candidates: () =>
    @rejects = []
    for candidate_node in @temp_nodes
      unless @should_cull(candidate_node)
        candidate_node.i = @node_id++
        @queue.push(candidate_node)
        @nodes.push(candidate_node)
        @q.add(candidate_node)
      else
        @rejects.push(candidate_node)
    @draw_circles()
    @rejects = []
    _.delay(@place_next_nodes, @STEP * 2)

  draw_circles: () ->
    @circles = @svg.selectAll("circle")
        .data(@nodes, (d) -> d.i)
      .enter().append("svg:circle")
        .attr("r", (d) -> d.r)
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)
     
    @queued_circles = @svg.selectAll("circle.queued")
      .data(@queue, (d) -> d.i)
        
    @queued_circles.enter().append("svg:circle")
        .attr("class", "queued")
        .attr("r", (d) -> d.r)
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)

    @queued_circles.exit().remove()

    @temp_circles = @svg.selectAll("circle.temp")
        .data(@temp_nodes)

    @temp_circles.enter().append("svg:circle")
        .attr("class", "temp")
        .attr("r", (d) -> d.r)
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)

    @temp_circles.exit().remove()

    @reject_circles = @svg.selectAll("circle.reject")
        .data(@rejects)

    @reject_circles.enter().append("svg:circle")
        .attr("class", "reject")
        .attr("r", (d) -> d.r)
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)

    @reject_circles.exit().remove()

    if @current_node
      @placement_circles = @svg.selectAll("circle.placement")
          .data([@current_node], (d) -> d.i)

      @placement_circles.enter().append("svg:circle")
          .attr("class", "placement")
          .attr("r", (d) -> d.r)
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)

      @placement_circles.exit().remove()


  pack: (a, b, c) ->
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

  collides: (node) ->
    r = node.r + 16
    nx1 = node.x - r
    nx2 = node.x + r
    ny1 = node.y - r
    ny2 = node.y + r
    collides = false
    @q.visit (quad, x1, y1, x2, y2) ->
      if (quad.point && (quad.point != node))
        x = node.x - quad.point.x
        y = node.y - quad.point.y
        l = Math.sqrt(x * x + y * y)
        r = node.r + quad.point.r
        if (r - l) > 0.001
          collides = true

      (x1 > nx2) || (x2 < nx1) || (y1 > ny2) || (y2 < ny1)
    collides

  should_cull: (node) ->
    {x, y, r} = node
    x + r < -@padding ||
    y + r < -@padding ||
    x - r > @w() + @padding ||
    y - r > @h() + @padding ||
    @collides(node)

  r_for_point: (x, y) ->
    @noise.for_point(x, y) * (@radius_max - @radius_min) + @radius_min

  w: () ->
    window.innerWidth

  h: () ->
    window.innerHeight

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
    # @canvas.style.display = "none"
    @visible = false

    window.addEventListener("resize", _.debounce(@draw, 0), false)
    window.addEventListener("keydown", ((e) =>
      return unless e.which is 78
      if @visible then display = "none" else display = "block"
      @canvas.style.display = display
      @visible = !@visible
    ), false)
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
  padding: 0
}

d3.select("#restart").on "click", () ->
  d3.event.preventDefault()
  window.location.reload()
