APP = null

class Color
  # from: https://www.w3.org/TR/2011/REC-css3-color-20110607/#hsl-color
  @hsl_to_rgb: (h, s, l) ->
    m2 = if l <= 0.5
      l * (s + 1)
    else
      l + s - (l * s)

    m1 = (l * 2) - m2

    return [
      Color.hue_to_rgb(m1, m2, h + (1 / 3)),
      Color.hue_to_rgb(m1, m2, h),
      Color.hue_to_rgb(m1, m2, h - (1 / 3))
    ]

  @hue_to_rgb: (m1, m2, h) ->
    h = h + 1 if h < 0
    h = h - 1 if h > 1

    return m1 + ((m2 - m1) * h * 6) if h * 6 < 1
    return m2 if h * 2 < 1
    return m1 + ((m2 - m1) * ((2 / 3) - h) * 6) if h * 3 < 2
    m1

  @component_to_hex: (x) ->
    str = Math.round(x * 255).toString(16);
    if str.length == 1
      '0' + str
    else
      str

  @hsl_to_hexrgb: (args...) ->
    hex = Color.hsl_to_rgb(args...).map(Color.component_to_hex)
    return "##{hex.join('')}"

  @hexrgb_to_rgb: (hexrgb) ->
    md = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hexrgb)
    if md
      return [
        parseInt(md[1], 16),
        parseInt(md[2], 16),
        parseInt(md[3], 16)
      ]
    else
      return [0,0,0]

  @hexrgb_and_alpha_to_rgba_str: (hexrgb, alpha) ->
    rgb = Color.hexrgb_to_rgb(hexrgb)
    "rgba(#{rgb[0]},#{rgb[1]},#{rgb[2]},#{alpha})"

class Point
  constructor: (@name, x, y, @move_perc = 0.5) ->
    x ?= APP.graph_ui_canvas.width / 2
    y ?= APP.graph_ui_canvas.height / 2

    @el_id = @name.toLowerCase()
    @info_x_id = 'point_' + @el_id + '_x'
    @info_y_id = 'point_' + @el_id + '_y'

    @move x, y

  update_text: () ->
    @info_x.textContent = @ix if @info_x
    @info_y.textContent = @iy if @info_y

  move_no_text_update: (x, y) ->
    @x = x
    @y = y
    @ix = Math.floor(@x)
    @iy = Math.floor(@y)

  move: (x, y) ->
    @move_no_text_update(x, y)
    @update_text()

  move_towards: (other, perc = other.move_perc) ->
    dx = other.x - (@x)
    dy = other.y - (@y)
    @move @x + dx * perc, @y + dy * perc

  move_towards_no_text_update: (other, perc = other.move_perc) ->
    dx = other.x - (@x)
    dy = other.y - (@y)
    @move_no_text_update @x + dx * perc, @y + dy * perc

  distance: (other) ->
    dx = @x - other.x
    dy = @y - other.y
    Math.sqrt((dx * dx) + (dy * dy))

class UIPoint extends Point
  constructor: (hue, args...) ->
    @set_color_hue(hue)
    super args...

  update_color_alpha_from_color: () ->
    @color_alpha = Color.hexrgb_and_alpha_to_rgba_str(@color, DrawPoint.ALPHA)

  set_color_hue: (hue) ->
    @color = Color.hsl_to_hexrgb(hue / 360, 1.0, 0.5)
    @update_color_alpha_from_color()

  set_color_hexrgb: (hexrgb) ->
    @color = hexrgb
    @update_color_alpha_from_color()

  draw_ui: () ->
    ctx = APP.graph_ui_ctx
    ctx.strokeStyle = @color
    ctx.strokeRect(@x - 2, @y - 2, 5, 5)

class PointWidget extends UIPoint
  @widgets = []
  @NEARBY_RADIUS = 8

  @nearby_widgets: (loc) ->
    @widgets.filter (w) =>
      w.distance(loc) < @NEARBY_RADIUS

  @first_nearby_widget: (loc) ->
    nearlist = PointWidget.nearby_widgets(loc)
    if nearlist?
      nearlist[0]
    else
      null

  @random_widget: () ->
    idx = parseInt(Math.random() * PointWidget.widgets.length)
    PointWidget.widgets[idx]

  @is_name_used: (name) ->
    for w in PointWidget.widgets
      return true if w.name == name
    return false

  @next_name: () ->
    for code in [65..90]
      str = String.fromCharCode(code)
      unless PointWidget.is_name_used(str)
        return str

    alert('sorry, cannot generate more than 26 point names')
    throw 'cannot generate a unique point name'

  @create: (opt) ->
    opt.name ?= PointWidget.next_name()
    opt.hue  ?= Math.random() * 360
    opt.move_perc ?= 0.5

    w = new PointWidget(opt.hue, opt.name, opt.x, opt.y, opt.move_perc)
    PointWidget.widgets.push(w)
    w

  constructor: (args...) ->
    super args...

    row = APP.point_pos_table.insertRow(-1)

    namecell = row.insertCell(0)
    namecell.textContent = @name

    @color_selector_el = document.createElement('input')
    @color_selector_el.type = 'color'
    @color_selector_el.value = @color
    @color_selector_el.addEventListener('change', @on_color_change)

    color_selector = row.insertCell(1)
    color_selector.appendChild(@color_selector_el)

    @info_x = row.insertCell(2)
    @info_x.textContent = @x

    @info_y = row.insertCell(3)
    @info_y.textContent = @y

    @move_perc_cell = row.insertCell(4)
    @move_perc_cell.textContent = @move_perc.toFixed(2)

    @move_per_range_el = document.createElement('input')
    @move_per_range_el.type = 'range'
    @move_per_range_el.min = 0
    @move_per_range_el.max = 1
    @move_per_range_el.step = 0.05
    @move_per_range_el.value = @move_perc
    @move_per_range_el.addEventListener('input', @on_move_per_range_input)

    move_perc_adj_cell = row.insertCell(5)
    move_perc_adj_cell.appendChild(@move_per_range_el)

  on_color_change: (event) =>
    @set_color_hexrgb(event.target.value)
    APP.resumable_reset()

  on_move_per_range_input: (event) =>
    @set_move_perc(event.target.value)
    APP.resumable_reset()

  set_move_perc: (newvalue) ->
    @move_perc = parseFloat(newvalue)
    @move_perc_cell.textContent = @move_perc.toFixed(2) if @move_perc_cell

class DrawPoint extends UIPoint
  @ALPHA = '0.333'

  constructor: (name) ->
    super '0', name

    @info_x = APP.context.getElementById(@info_x_id)
    @info_y = APP.context.getElementById(@info_y_id)

    @color = '#000'

  draw_graph: (target) ->
    ctx = APP.graph_ctx
    ctx.fillStyle = target.color_alpha
    ctx.fillRect(@x, @y, 1, 1)

class StochasticSierpinski
  constructor: (@context) ->

  init: () ->
    @running = false

    @steps_per_frame = 100
    @step_count = 0

    @steps_per_frame_el = @context.getElementById('steps_per_frame')
    @steps_per_frame_el.value = if @steps_per_frame == 1
      0
    else
      @steps_per_frame

    @graph_canvas    = @context.getElementById('graph')
    @graph_ui_canvas = @context.getElementById('graph_ui')

    @graph_ctx    = @graph_canvas.getContext('2d', alpha: true)
    @graph_ui_ctx = @graph_ui_canvas.getContext('2d', alpha: true)

    @btn_reset = @context.getElementById('button_reset')
    @btn_step  = @context.getElementById('button_step')
    @btn_run   = @context.getElementById('button_run')

    @total_steps_cell = @context.getElementById('total_steps')
    @point_pos_table  = @context.getElementById('point_pos_table')

    PointWidget.create
      hue: '0'
      x: 210
      y: 20

    PointWidget.create
      hue: '120'
      x: 40
      y: 300

    PointWidget.create
      hue: '240'
      x: 380
      y: 300

    PointWidget.create
      x: 210
      y: 210
      move_perc: 0.85

    @cur  = new DrawPoint('Cur')

    @steps_per_frame_el.addEventListener 'input', @on_steps_per_frame_input

    @btn_reset.addEventListener 'click', @on_reset
    @btn_step.addEventListener  'click', @on_step
    @btn_run.addEventListener   'click', @on_run

    @graph_ui_canvas.addEventListener 'mousedown', @on_mousedown
    @graph_ui_canvas.addEventListener 'mouseup',   @on_mouseup
    @graph_ui_canvas.addEventListener 'mousemove', @on_mousemove

    @update_info_elements()
    @draw()

  on_steps_per_frame_input: (event) =>
    @steps_per_frame = event.target.value
    @steps_per_frame = 1 if @steps_per_frame < 1

  update_info_elements: () ->
    @total_steps_cell.textContent = @step_count
    @cur.update_text()

  event_to_canvas_loc: (event) ->
    return
      x: event.layerX
      y: event.layerY

  is_inside_ui: (loc) ->
    return (
      (0 <= loc.x <= @graph_ui_canvas.width) and
      (0 <= loc.y <= @graph_ui_canvas.height))

  on_mousedown: (event) =>
    loc = @event_to_canvas_loc(event)
    w = PointWidget.first_nearby_widget(loc)
    if w?
      @dnd_target = w

  on_mouseup: (event) =>
    if @dnd_target?
      loc = @event_to_canvas_loc(event)
      if @is_inside_ui(loc)
        @dnd_target.move(loc.x, loc.y)
        @draw()
        @resumable_reset()

      @dnd_target = null

  on_mousemove: (event) =>
    if @dnd_target?
      loc = @event_to_canvas_loc(event)
      if @is_inside_ui(loc)
        @dnd_target.move(loc.x, loc.y)
        @draw()
        @resumable_reset()

  resumable_reset: () =>
    @on_reset(true)

  on_reset: (restart_ok = false) =>
    was_running = @running
    @stop()

    @cur.move(
      @graph_ui_canvas.width / 2,
      @graph_ui_canvas.height / 2)

    @step_count = 0

    @update_info_elements()

    @graph_ctx.clearRect(0, 0, @graph_canvas.width, @graph_canvas.height)

    @draw()

    @start() if restart_ok and was_running

  on_step: =>
    if @running
      @stop()
    else
      @step()

  on_run: =>
    if @running
      @stop()
    else
      @start()

  start: =>
    @running = true
    @btn_run.textContent = 'Pause'
    @schedule_next_frame()

  stop: =>
    @running = false
    @btn_run.textContent = 'Run'

  single_step: ->
    target = PointWidget.random_widget()
    if target?
      @cur.move_towards_no_text_update target
      @cur.draw_graph(target)
      @step_count += 1

  step: =>
    @single_step() for [0...@steps_per_frame]

    @update_info_elements()
    @draw()

  draw: =>
    @graph_ui_ctx.clearRect(0, 0, @graph_ui_canvas.width, @graph_ui_canvas.height)

    @cur.draw_ui()

    for p in PointWidget.widgets
      p.draw_ui()

  update: =>
    @step()
    @schedule_next_frame() if @running

  schedule_next_frame: () ->
    window.requestAnimationFrame(@update)

document.addEventListener 'DOMContentLoaded', =>
  APP = new StochasticSierpinski(document)
  APP.init()
