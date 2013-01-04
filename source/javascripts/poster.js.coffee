class Poster
  constructor: () ->
    @force = null

  nodes: () ->

class Noise
  constructor: (@scale) ->
    @simplex = new SimplexNoise

  for_point: (x, y) ->
    x = x / @scale
    y = y / @scale

    @simplex.noise2D(x, y) * 0.5 + 0.5 # translate from -1-1 to 0-1


class NoiseCanvas
  constructor: (options) ->
    {@noise, @opacity} = options
    @opacity *= 255
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

window.n = new Noise 256
window.nc = new NoiseCanvas noise: window.n, opacity: 0.5
