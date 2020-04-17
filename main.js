(function() {
  var Point, StochasticSierpinski;

  Point = (function() {
    Point.prototype.move_perc = 0.5;

    function Point(app, name, x, y) {
      this.app  = app;
      this.name = name;
      this.id   = name.toLowerCase();

      this.info_x = app.context.getElementById("point_" + this.id + "_x");
      this.info_y = app.context.getElementById("point_" + this.id + "_y");

      this.move(x, y);
    }

    Point.prototype.move = function(x, y) {
      this.x = x;
      this.y = y;

      this.ix = Math.floor(this.x);
      this.iy = Math.floor(this.y);

      if (this.info_x) {
        this.info_x.textContent = this.ix;
      }

      if (this.info_y) {
        this.info_y.textContent = this.iy;
      }
    };

    Point.prototype.move_towards = function(other, perc) {
      if (perc == null) {
        perc = this.move_perc;
      }
      var dx = other.x - this.x;
      var dy = other.y - this.y;
      this.move(this.x + (dx * perc),
                this.y + (dy * perc));
    };

    return Point;
  })();

  StochasticSierpinski = (function() {
    function StochasticSierpinski(context) {
      this.running = false;

      this.context = context;
      this.canvas = this.context.getElementById("graph");
      this.ctx = this.canvas.getContext('2d', { alpha: false });

      this.btn_reset = this.context.getElementById("button_reset");
      this.btn_step  = this.context.getElementById("button_step");
      this.btn_run   = this.context.getElementById("button_run");

      this.a = new Point(this, "A", 210,  20);
      this.b = new Point(this, "B",  40, 300);
      this.c = new Point(this, "C", 380, 300);

      this.points = [this.a, this.b, this.c];

      this.cur  = new Point(this,  "Cur", this.a.x,   this.a.y);
      this.prev = new Point(this, "Prev", this.cur.x, this.cur.y);

      var that = this;
      this.btn_reset.addEventListener("click", function() {
        that.on_reset();
      });
      this.btn_step.addEventListener("click", function() {
        that.on_step();
      });
      this.btn_run.addEventListener("click", function() {
        that.on_run();
      });
    }

    StochasticSierpinski.prototype.on_reset = function() {
    };

    StochasticSierpinski.prototype.on_step = function() {
      if (this.running) {
        this.stop();
      } else {
        this.step();
      }
    };

    StochasticSierpinski.prototype.on_run = function() {
      if (this.running) {
        this.stop();
      } else {
        this.start();
      }
    };

    StochasticSierpinski.prototype.start = function() {
      this.running = true;
      this.btn_run.textContent = 'Pause';
    };

    StochasticSierpinski.prototype.stop = function() {
      this.running = false;
      this.btn_run.textContent = 'Run';
    };

    StochasticSierpinski.prototype.random_point = function() {
      var rand = Math.random() * 3;
      if (rand < 1) {
        return this.a;
      }
      if (rand < 2) {
        return this.b;
      } else {
        return this.c;
      }
    };

    StochasticSierpinski.prototype.step = function() {
      this.prev.move(this.cur.x, this.cur.y);

      var target = this.random_point();
      this.cur.move_towards(target, 0.5);
    };

    return StochasticSierpinski;
  })();

  document.addEventListener("DOMContentLoaded", function() {
    new StochasticSierpinski(document);
  });

}).call(this);
