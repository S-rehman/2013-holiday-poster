class Poster
  constructor: (options) ->
    {
      @json_url
    } = options

    @init_text()

    @svg = d3.select(document.body).append("svg:svg")
      .attr("width", @w())
      .attr("height", @h())

    d3.json @json_url, (e, data) =>
      @nodes = _.filter(data, (d) =>
          +d.cx < @w() && +d.cy < @h() )
        .map( (d) ->
          d.r = Math.round(d.r)
          d.cx = Math.round(d.cx)
          d.cy = Math.round(d.cy)
          d )
      @circles = @svg.selectAll("circle")
          .data(@nodes)
        .enter().append("svg:circle")
          .attr("r", (d) -> d.r)
          .attr("cx", (d) -> d.cx)
          .attr("cy", (d) -> d.cy)
          .style("opacity", 0)
      @circles.transition()
        # .delay( (d, i) -> (+d.cx + +d.cy) * (20/+d.r) + 1000 )
        # .delay( (d, i) -> (+d.cx + +d.cy) + 1000 )
        .duration( (d, i) ->
          duration = (20 / +d.r) * 4000
          window.durations ?= []
          window.durations.push duration
          Math.min(duration, 6000)
        )
        # .duration(4000)
        .style("opacity", 0.3)

      # @circles.on "click", (d,i) ->
        # d3.select(this)
          # .transition()
          # .duration(400)
          # .ease(Math.sqrt)
          # .style("opacity", 0)
          # .attr("r", (d) -> d.r * 4 )
          # .remove()

      _.delay(@glimmer, 6000)

  init_text: () ->
    @heading = document.querySelector("h1")
    h = (@h() - @heading.clientHeight) / 2
    @heading.style.top = "#{h}px"
    @heading.style.visibility = "visible"


  glimmer: () =>
    @circles.transition()
        .duration(3000)
        .delay( (d, i) -> d.cx + d.cy)
        .style("opacity", (d) -> 0.3 + (d.r/30) * 0.7)
        .attr("cx", (d) -> +d.cx + (+d.r/30) * 3)
        # .attr("cy", (d) -> d.cy - 2)
        # .ease("quad-in")
      .transition()
        .duration(3000)
        .style("opacity", 0.3)
        .attr("cx", (d) -> d.cx - (d.r/30) * 3)
        # .attr("cy", (d) -> d.cy + 2)
        # .ease("quad-out")
        # .attr("transform", "translateX(-5,0)")
    _.delay(@glimmer, 6000 + Math.random() * 4000)
  
  w: () ->
    window.innerWidth

  h: () ->
    window.innerHeight

window.poster = new Poster {
  json_url: "/javascripts/bubbles.json"
}

