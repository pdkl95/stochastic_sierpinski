(function() {
  var APP, Color, DrawPoint, Point, PointWidget, StochasticSierpinski, UIPoint,
    slice = [].slice,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  APP = null;

  Color = (function() {
    function Color() {}

    Color.hsl_to_rgb = function(h, s, l) {
      var m1, m2;
      m2 = l <= 0.5 ? l * (s + 1) : l + s - (l * s);
      m1 = (l * 2) - m2;
      return [Color.hue_to_rgb(m1, m2, h + (1 / 3)), Color.hue_to_rgb(m1, m2, h), Color.hue_to_rgb(m1, m2, h - (1 / 3))];
    };

    Color.hue_to_rgb = function(m1, m2, h) {
      if (h < 0) {
        h = h + 1;
      }
      if (h > 1) {
        h = h - 1;
      }
      if (h * 6 < 1) {
        return m1 + ((m2 - m1) * h * 6);
      }
      if (h * 2 < 1) {
        return m2;
      }
      if (h * 3 < 2) {
        return m1 + ((m2 - m1) * ((2 / 3) - h) * 6);
      }
      return m1;
    };

    Color.component_to_hex = function(x) {
      var str;
      str = Math.round(x * 255).toString(16);
      if (str.length === 1) {
        return '0' + str;
      } else {
        return str;
      }
    };

    Color.hsl_to_hexrgb = function() {
      var args, hex;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      hex = Color.hsl_to_rgb.apply(Color, args).map(Color.component_to_hex);
      return "#" + (hex.join(''));
    };

    Color.hexrgb_to_rgb = function(hexrgb) {
      var md;
      md = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hexrgb);
      if (md) {
        return [parseInt(md[1], 16), parseInt(md[2], 16), parseInt(md[3], 16)];
      } else {
        return [0, 0, 0];
      }
    };

    Color.hexrgb_and_alpha_to_rgba_str = function(hexrgb, alpha) {
      var rgb;
      rgb = Color.hexrgb_to_rgb(hexrgb);
      return "rgba(" + rgb[0] + "," + rgb[1] + "," + rgb[2] + "," + alpha + ")";
    };

    return Color;

  })();

  Point = (function() {
    function Point(name1, x, y, move_perc) {
      this.name = name1;
      this.move_perc = move_perc != null ? move_perc : 0.5;
      if (x == null) {
        x = APP.graph_ui_canvas.width / 2;
      }
      if (y == null) {
        y = APP.graph_ui_canvas.height / 2;
      }
      this.el_id = this.name.toLowerCase();
      this.info_x_id = 'point_' + this.el_id + '_x';
      this.info_y_id = 'point_' + this.el_id + '_y';
      this.move(x, y);
    }

    Point.prototype.update_text = function() {
      if (this.info_x) {
        this.info_x.textContent = this.ix;
      }
      if (this.info_y) {
        return this.info_y.textContent = this.iy;
      }
    };

    Point.prototype.move_no_text_update = function(x, y) {
      this.x = x;
      this.y = y;
      this.ix = Math.floor(this.x);
      return this.iy = Math.floor(this.y);
    };

    Point.prototype.move = function(x, y) {
      this.move_no_text_update(x, y);
      return this.update_text();
    };

    Point.prototype.move_towards = function(other, perc) {
      var dx, dy;
      if (perc == null) {
        perc = other.move_perc;
      }
      dx = other.x - this.x;
      dy = other.y - this.y;
      return this.move(this.x + dx * perc, this.y + dy * perc);
    };

    Point.prototype.move_towards_no_text_update = function(other, perc) {
      var dx, dy;
      if (perc == null) {
        perc = other.move_perc;
      }
      dx = other.x - this.x;
      dy = other.y - this.y;
      return this.move_no_text_update(this.x + dx * perc, this.y + dy * perc);
    };

    Point.prototype.distance = function(other) {
      var dx, dy;
      dx = this.x - other.x;
      dy = this.y - other.y;
      return Math.sqrt((dx * dx) + (dy * dy));
    };

    return Point;

  })();

  UIPoint = (function(superClass) {
    extend(UIPoint, superClass);

    function UIPoint() {
      var args, hue;
      hue = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this.set_color_hue(hue);
      UIPoint.__super__.constructor.apply(this, args);
    }

    UIPoint.prototype.update_color_alpha_from_color = function() {
      this.color_alpha = Color.hexrgb_and_alpha_to_rgba_str(this.color, DrawPoint.ALPHA);
      return console.log('@color =', this.color, '@color_alpha =', this.color_alpha);
    };

    UIPoint.prototype.set_color_hue = function(hue) {
      this.color = Color.hsl_to_hexrgb(hue / 360, 1.0, 0.5);
      return this.update_color_alpha_from_color();
    };

    UIPoint.prototype.set_color_hexrgb = function(hexrgb) {
      this.color = hexrgb;
      return this.update_color_alpha_from_color();
    };

    UIPoint.prototype.draw_ui = function() {
      var ctx;
      ctx = APP.graph_ui_ctx;
      ctx.strokeStyle = this.color;
      return ctx.strokeRect(this.x - 2, this.y - 2, 5, 5);
    };

    return UIPoint;

  })(Point);

  PointWidget = (function(superClass) {
    extend(PointWidget, superClass);

    PointWidget.widgets = [];

    PointWidget.NEARBY_RADIUS = 8;

    PointWidget.nearby_widgets = function(loc) {
      return this.widgets.filter((function(_this) {
        return function(w) {
          return w.distance(loc) < _this.NEARBY_RADIUS;
        };
      })(this));
    };

    PointWidget.first_nearby_widget = function(loc) {
      var nearlist;
      nearlist = PointWidget.nearby_widgets(loc);
      if (nearlist != null) {
        return nearlist[0];
      } else {
        return null;
      }
    };

    PointWidget.random_widget = function() {
      var idx;
      idx = parseInt(Math.random() * PointWidget.widgets.length);
      return PointWidget.widgets[idx];
    };

    PointWidget.is_name_used = function(name) {
      var i, len, ref, w;
      ref = PointWidget.widgets;
      for (i = 0, len = ref.length; i < len; i++) {
        w = ref[i];
        if (w.name === name) {
          return true;
        }
      }
      return false;
    };

    PointWidget.next_name = function() {
      var code, i, str;
      for (code = i = 65; i <= 90; code = ++i) {
        str = String.fromCharCode(code);
        if (!PointWidget.is_name_used(str)) {
          return str;
        }
      }
      alert('sorry, cannot generate more than 26 point names');
      throw 'cannot generate a unique point name';
    };

    PointWidget.create = function(opt) {
      var w;
      if (opt.name == null) {
        opt.name = PointWidget.next_name();
      }
      if (opt.hue == null) {
        opt.hue = Math.random() * 360;
      }
      if (opt.move_perc == null) {
        opt.move_perc = 0.5;
      }
      w = new PointWidget(opt.hue, opt.name, opt.x, opt.y, opt.move_perc);
      PointWidget.widgets.push(w);
      return w;
    };

    function PointWidget() {
      var args, color_selector, move_perc_adj_cell, namecell, row;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      this.on_move_per_range_input = bind(this.on_move_per_range_input, this);
      this.on_color_change = bind(this.on_color_change, this);
      PointWidget.__super__.constructor.apply(this, args);
      row = APP.point_pos_table.insertRow(-1);
      namecell = row.insertCell(0);
      namecell.textContent = this.name;
      this.color_selector_el = document.createElement('input');
      this.color_selector_el.type = 'color';
      this.color_selector_el.value = this.color;
      this.color_selector_el.addEventListener('change', this.on_color_change);
      color_selector = row.insertCell(1);
      color_selector.appendChild(this.color_selector_el);
      this.info_x = row.insertCell(2);
      this.info_x.textContent = this.x;
      this.info_y = row.insertCell(3);
      this.info_y.textContent = this.y;
      this.move_perc_cell = row.insertCell(4);
      this.move_perc_cell.textContent = this.move_perc.toFixed(2);
      this.move_per_range_el = document.createElement('input');
      this.move_per_range_el.type = 'range';
      this.move_per_range_el.min = 0;
      this.move_per_range_el.max = 1;
      this.move_per_range_el.step = 0.05;
      this.move_per_range_el.value = this.move_perc;
      this.move_per_range_el.addEventListener('input', this.on_move_per_range_input);
      move_perc_adj_cell = row.insertCell(5);
      move_perc_adj_cell.appendChild(this.move_per_range_el);
    }

    PointWidget.prototype.on_color_change = function(event) {
      this.set_color_hexrgb(event.target.value);
      return APP.resumable_reset();
    };

    PointWidget.prototype.on_move_per_range_input = function(event) {
      this.set_move_perc(event.target.value);
      return APP.resumable_reset();
    };

    PointWidget.prototype.set_move_perc = function(newvalue) {
      this.move_perc = parseFloat(newvalue);
      if (this.move_perc_cell) {
        return this.move_perc_cell.textContent = this.move_perc.toFixed(2);
      }
    };

    return PointWidget;

  })(UIPoint);

  DrawPoint = (function(superClass) {
    extend(DrawPoint, superClass);

    DrawPoint.ALPHA = '0.333';

    function DrawPoint(name) {
      DrawPoint.__super__.constructor.call(this, '0', name);
      this.info_x = APP.context.getElementById(this.info_x_id);
      this.info_y = APP.context.getElementById(this.info_y_id);
      this.color = '#000';
    }

    DrawPoint.prototype.draw_graph = function(target) {
      var ctx;
      ctx = APP.graph_ctx;
      ctx.fillStyle = target.color_alpha;
      return ctx.fillRect(this.x, this.y, 1, 1);
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
      this.resumable_reset = bind(this.resumable_reset, this);
      this.on_mousemove = bind(this.on_mousemove, this);
      this.on_mouseup = bind(this.on_mouseup, this);
      this.on_mousedown = bind(this.on_mousedown, this);
      this.on_steps_per_frame_input = bind(this.on_steps_per_frame_input, this);
    }

    StochasticSierpinski.prototype.init = function() {
      this.running = false;
      this.steps_per_frame = 100;
      this.step_count = 0;
      this.steps_per_frame_el = this.context.getElementById('steps_per_frame');
      this.steps_per_frame_el.value = this.steps_per_frame === 1 ? 0 : this.steps_per_frame;
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
      this.total_steps_cell = this.context.getElementById('total_steps');
      this.point_pos_table = this.context.getElementById('point_pos_table');
      PointWidget.create({
        hue: '0',
        x: 210,
        y: 20
      });
      PointWidget.create({
        hue: '120',
        x: 40,
        y: 300
      });
      PointWidget.create({
        hue: '240',
        x: 380,
        y: 300
      });
      PointWidget.create({
        x: 210,
        y: 210,
        move_perc: 0.85
      });
      this.cur = new DrawPoint('Cur');
      this.steps_per_frame_el.addEventListener('input', this.on_steps_per_frame_input);
      this.btn_reset.addEventListener('click', this.on_reset);
      this.btn_step.addEventListener('click', this.on_step);
      this.btn_run.addEventListener('click', this.on_run);
      this.graph_ui_canvas.addEventListener('mousedown', this.on_mousedown);
      this.graph_ui_canvas.addEventListener('mouseup', this.on_mouseup);
      this.graph_ui_canvas.addEventListener('mousemove', this.on_mousemove);
      this.update_info_elements();
      return this.draw();
    };

    StochasticSierpinski.prototype.on_steps_per_frame_input = function(event) {
      this.steps_per_frame = event.target.value;
      if (this.steps_per_frame < 1) {
        return this.steps_per_frame = 1;
      }
    };

    StochasticSierpinski.prototype.update_info_elements = function() {
      this.total_steps_cell.textContent = this.step_count;
      return this.cur.update_text();
    };

    StochasticSierpinski.prototype.event_to_canvas_loc = function(event) {
      return {
        x: event.layerX,
        y: event.layerY
      };
    };

    StochasticSierpinski.prototype.is_inside_ui = function(loc) {
      var ref, ref1;
      return ((0 <= (ref = loc.x) && ref <= this.graph_ui_canvas.width)) && ((0 <= (ref1 = loc.y) && ref1 <= this.graph_ui_canvas.height));
    };

    StochasticSierpinski.prototype.on_mousedown = function(event) {
      var loc, w;
      loc = this.event_to_canvas_loc(event);
      w = PointWidget.first_nearby_widget(loc);
      if (w != null) {
        return this.dnd_target = w;
      }
    };

    StochasticSierpinski.prototype.on_mouseup = function(event) {
      var loc;
      if (this.dnd_target != null) {
        loc = this.event_to_canvas_loc(event);
        if (this.is_inside_ui(loc)) {
          this.dnd_target.move(loc.x, loc.y);
          this.draw();
          this.resumable_reset();
        }
        return this.dnd_target = null;
      }
    };

    StochasticSierpinski.prototype.on_mousemove = function(event) {
      var loc;
      if (this.dnd_target != null) {
        loc = this.event_to_canvas_loc(event);
        if (this.is_inside_ui(loc)) {
          this.dnd_target.move(loc.x, loc.y);
          this.draw();
          return this.resumable_reset();
        }
      }
    };

    StochasticSierpinski.prototype.resumable_reset = function() {
      return this.on_reset(true);
    };

    StochasticSierpinski.prototype.on_reset = function(restart_ok) {
      var was_running;
      if (restart_ok == null) {
        restart_ok = false;
      }
      was_running = this.running;
      this.stop();
      this.cur.move(this.graph_ui_canvas.width / 2, this.graph_ui_canvas.height / 2);
      this.step_count = 0;
      this.update_info_elements();
      this.graph_ctx.clearRect(0, 0, this.graph_canvas.width, this.graph_canvas.height);
      this.draw();
      if (restart_ok && was_running) {
        return this.start();
      }
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

    StochasticSierpinski.prototype.single_step = function() {
      var target;
      target = PointWidget.random_widget();
      if (target != null) {
        this.cur.move_towards_no_text_update(target);
        this.cur.draw_graph(target);
        return this.step_count += 1;
      }
    };

    StochasticSierpinski.prototype.step = function() {
      var i, ref;
      for (i = 0, ref = this.steps_per_frame; 0 <= ref ? i < ref : i > ref; 0 <= ref ? i++ : i--) {
        this.single_step();
      }
      this.update_info_elements();
      return this.draw();
    };

    StochasticSierpinski.prototype.draw = function() {
      var i, len, p, ref, results;
      this.graph_ui_ctx.clearRect(0, 0, this.graph_ui_canvas.width, this.graph_ui_canvas.height);
      this.cur.draw_ui();
      ref = PointWidget.widgets;
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
      APP = new StochasticSierpinski(document);
      return APP.init();
    };
  })(this));

}).call(this);
