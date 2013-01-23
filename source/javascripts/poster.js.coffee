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
          duration = (20 / +d.r) * 8000
          Math.min(duration, 10000)
        )
        .style("opacity", 0.4)

      _.delay(@glimmer, 10000)

  init_text: () ->
    h = @h
    delay_for = 4000
    @heading = d3.select("h1")
        .style("top", () -> "#{(h - @clientHeight) / 2}px" )
        .style("visibility", "visible")

    @heading.selectAll("span")
      .style("opacity", 0)

    _.delay( () =>
      @heading.selectAll("span")
        .transition()
          .duration(1500)
          .delay( (d, i) -> 1500 * i )
          .style("opacity", 1)
    , delay_for)

    _.delay( ()=>
      d3.select("footer")
        .transition()
        .duration(1500)
        .style("opacity", 1)
    , delay_for + 1500*4)


  glimmer: () =>
    @glimmer_count ?= 0
    return if @glimmer_count++ > 10

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
        .style("opacity", (d) -> 0.4 + (d.r/30) * 0.6)
      .transition()
        .duration(1000)
        .style("opacity", 0.1)
      .transition()
        .duration(2000)
        .style("opacity", 0.4)
    _.delay(@glimmer, 6000 + Math.random() * 4000)
  
  width: () ->
    window.innerWidth

  height: () ->
    window.innerHeight

window.poster = new Poster {
  json_url: "/javascripts/bubbles.json"
}

