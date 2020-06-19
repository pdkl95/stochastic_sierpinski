(function() {
  var DrawPoint, Point, PointWidget, StochasticSierpinski, UIPoint,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Point = (function() {
    function Point(app, name, x, y) {
      this.app = app;
      this.name = name;
      this.el_id = this.name.toLowerCase();
      this.info_x = this.app.context.getElementById('point_' + this.el_id + '_x');
      this.info_y = this.app.context.getElementById('point_' + this.el_id + '_y');
      this.move(x, y);
      this.move_perc = 0.5;
    }

    Point.prototype.move = function(x, y) {
      this.x = x;
      this.y = y;
      this.ix = Math.floor(this.x);
      this.iy = Math.floor(this.y);
      if (this.info_x) {
        this.info_x.textContent = '' + this.ix;
      }
      if (this.info_y) {
        return this.info_y.textContent = '' + this.iy;
      }
    };

    Point.prototype.move_towards = function(other, perc) {
      var dx, dy;
      if (perc == null) {
        perc = this.move_perc;
      }
      dx = other.x - this.x;
      dy = other.y - this.y;
      return this.move(this.x + dx * perc, this.y + dy * perc);
    };

    return Point;

  })();

  UIPoint = (function(superClass) {
    extend(UIPoint, superClass);

    function UIPoint() {
      var args, hue;
      hue = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this.color = 'hsl(' + hue + ', 100%, 50%)';
      this.color_alpha = 'hsla(' + hue + ', 100%, 50%, ' + DrawPoint.ALPHA + ')';
      UIPoint.__super__.constructor.apply(this, args);
    }

    UIPoint.prototype.draw_ui = function() {
      var ctx;
      ctx = this.app.graph_ui_ctx;
      ctx.strokeStyle = this.color;
      return ctx.strokeRect(this.x - 2, this.y - 2, 5, 5);
    };

    return UIPoint;

  })(Point);

  PointWidget = (function(superClass) {
    extend(PointWidget, superClass);

    function PointWidget() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      PointWidget.__super__.constructor.apply(this, args);
    }

    return PointWidget;

  })(UIPoint);

  DrawPoint = (function(superClass) {
    extend(DrawPoint, superClass);

    DrawPoint.ALPHA = '0.333';

    function DrawPoint() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      DrawPoint.__super__.constructor.apply(this, args);
      this.color = '#000';
    }

    DrawPoint.prototype.draw_graph = function(target) {
      var ctx;
      ctx = this.app.graph_ctx;
      ctx.fillStyle = target.color_alpha;
      return ctx.fillRect(this.x - 1, this.y - 1, 3, 3);
    };

    return DrawPoint;

  })(UIPoint);

  StochasticSierpinski = (function() {
    function StochasticSierpinski(context) {
      this.context = context;
      this.update = bind(this.update, this);
      this.draw = bind(this.draw, this);
      this.step = bind(this.step, this);
      this.stop = bind(this.stop, this);
      this.start = bind(this.start, this);
      this.on_run = bind(this.on_run, this);
      this.on_step = bind(this.on_step, this);
      this.on_reset = bind(this.on_reset, this);
      this.running = false;
      this.graph_canvas = this.context.getElementById('graph');
      this.graph_ui_canvas = this.context.getElementById('graph_ui');
      this.graph_ctx = this.graph_canvas.getContext('2d', {
        alpha: true
      });
      this.graph_ui_ctx = this.graph_ui_canvas.getContext('2d', {
        alpha: true
      });
      this.btn_reset = this.context.getElementById('button_reset');
      this.btn_step = this.context.getElementById('button_step');
      this.btn_run = this.context.getElementById('button_run');
      this.a = new PointWidget('0', this, 'A', 210, 20);
      this.b = new PointWidget('120', this, 'B', 40, 300);
      this.c = new PointWidget('240', this, 'C', 380, 300);
      this.points = [this.a, this.b, this.c];
      this.cur = new DrawPoint('0', this, 'Cur', this.a.x, this.a.y);
      this.btn_reset.addEventListener('click', this.on_reset);
      this.btn_step.addEventListener('click', this.on_step);
      this.btn_run.addEventListener('click', this.on_run);
      this.draw();
    }

    StochasticSierpinski.prototype.on_reset = function() {
      this.stop();
      return this.graph_ctx.clearRect(0, 0, this.graph_canvas.width, this.graph_canvas.height);
    };

    StochasticSierpinski.prototype.on_step = function() {
      if (this.running) {
        return this.stop();
      } else {
        return this.step();
      }
    };

    StochasticSierpinski.prototype.on_run = function() {
      if (this.running) {
        return this.stop();
      } else {
        return this.start();
      }
    };

    StochasticSierpinski.prototype.start = function() {
      this.running = true;
      this.btn_run.textContent = 'Pause';
      return this.schedule_next_frame();
    };

    StochasticSierpinski.prototype.stop = function() {
      this.running = false;
      return this.btn_run.textContent = 'Run';
    };

    StochasticSierpinski.prototype.random_point = function() {
      var rand;
      rand = Math.random() * 3;
      if (rand < 1) {
        return this.a;
      }
      if (rand < 2) {
        return this.b;
      }
      return this.c;
    };

    StochasticSierpinski.prototype.step = function() {
      var target;
      target = this.random_point();
      this.cur.move_towards(target, 0.5);
      this.cur.draw_graph(target);
      return this.draw();
    };

    StochasticSierpinski.prototype.draw = function() {
      var i, len, p, ref, results;
      this.graph_ui_ctx.clearRect(0, 0, this.graph_ui_canvas.width, this.graph_ui_canvas.height);
      this.cur.draw_ui();
      ref = this.points;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        p = ref[i];
        results.push(p.draw_ui());
      }
      return results;
    };

    StochasticSierpinski.prototype.update = function() {
      this.step();
      if (this.running) {
        return this.schedule_next_frame();
      }
    };

    StochasticSierpinski.prototype.schedule_next_frame = function() {
      return window.requestAnimationFrame(this.update);
    };

    return StochasticSierpinski;

  })();

  document.addEventListener('DOMContentLoaded', (function(_this) {
    return function() {
      return new StochasticSierpinski(document);
    };
  })(this));

}).call(this);
