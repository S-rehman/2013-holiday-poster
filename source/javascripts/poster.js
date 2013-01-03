var canvas = document.getElementById("c");
var ctx = canvas.getContext("2d");
var r = 50;
var i, l;
var noise = [];
var simplex = new SimplexNoise();

function Circle (x, y, r) {
  this.x = x;
  this.y = y;
  this.r = r;
}

Circle.prototype = {
  draw: function (ctx) {
    // ctx.save();
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.r, 0, Math.PI*2, true);
    ctx.closePath();
    ctx.stroke();
    // ctx.restore():
  }
};

function draw () {
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  console.log(canvas.width);
  console.log(canvas.height);
  generateNoise();
  drawPoints();
}

window.addEventListener("resize", _.debounce(draw, 0), false);

function generateNoise () {
  var w = canvas.width;
  var h = canvas.height;
  var imageData = ctx.getImageData(0, 0, w, h);
  var data = imageData.data;
  var x, y, b, xOff, yOff;

  // noise = new Array(w * h);

  for (y = 0; y < h; y++) {
    for (x = 0; x < w; x++) {
      yOff = y * w * 4;
      xOff = x * 4;
      b = brightnessForPoint(x, y);
      noise[y * w + x] = b / 255;
      data[yOff + xOff + 0] = b;
      data[yOff + xOff + 1] = b;
      data[yOff + xOff + 2] = b;
      data[yOff + xOff + 3] = 0;
    }
  }

  ctx.putImageData(imageData, 0, 0);
}

function drawPoints () {
  var w = canvas.width;
  var h = canvas.height;
  var step = 10;
  var x, y, weight;

  for (y = 0; y < h; y+=step) {
    for (x = 0; x < w; x+=step) {
      weight = noise[y * w + x];
      ctx.fillStyle = "rgba(185, 175, 165, " + weight + ")";
      ctx.fillRect(x, y, weight * step, weight * step);
    }
  }
}

function brightnessForPoint (x, y) {
  var scale = 256;
  x = x / scale;
  y = y / scale;
  var n = simplex.noise2D(x, y) * 0.5 + 0.5; // translate from -1-1 to 0-1
  return Math.round(n * 255);
}

draw();

