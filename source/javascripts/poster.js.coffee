class Poster
  constructor: (options) ->
    {
      @json_url
    } = options

    @w = @width()
    @h = @height()

    @init_text()
    
    @svg = d3.select(document.body).append("svg:svg")
      .attr("width", @w)
      .attr("height", @h)
      .append("g")

    d3.json @json_url, (e, data) =>
      @nodes = _.filter(data, (d) =>
          +d.cx < @w && +d.cy < @h )
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
        .duration( (d, i) ->
          duration = (20 / +d.r) * 4000
          Math.min(duration, 6000)
        )
        .style("opacity", 0.3)

      _.delay(@glimmer, 6000)

  init_text: () ->
    @heading = document.querySelector("h1")
    h = (@h - @heading.clientHeight) / 2
    @heading.style.top = "#{h}px"
    @heading.style.visibility = "visible"


  glimmer: () =>
    @glimmer_count ?= 0
    return unless @glimmer_count++ < 10
    cx = parseInt Math.random() * @w
    cy = parseInt Math.random() * @h

    if Math.random() > 0.5
      if Math.random() > 0.5 then cx = 0 else cx = @w
    else
      if Math.random() > 0.5 then cy = 0 else cy = @h

    @circles.transition()
        .duration(1000)
        .delay( (d, i) =>

          d1 = d.cx - cx
          d2 = d.cy - cy
          Math.sqrt(d1*d1 + d2*d2)
        )
        .style("opacity", (d) -> 0.1 + (d.r/30) * 0.7)
      .transition()
        .duration(1000)
        .style("opacity", 0.1)
      .transition()
        .duration(2000)
        .style("opacity", 0.3)
    _.delay(@glimmer, 6000 + Math.random() * 4000)
  
  width: () ->
    window.innerWidth

  height: () ->
    window.innerHeight

window.poster = new Poster {
  json_url: "/javascripts/bubbles.json"
}

