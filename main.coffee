APP = null

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

class UIPoint extends Point
  constructor: (hue, args...) ->
    @color       = 'hsl(' + hue + ', 100%, 50%)'
    @color_alpha = 'hsla(' + hue + ', 100%, 50%, ' + DrawPoint.ALPHA + ')'
    super args...

  draw_ui: () ->
    ctx = APP.graph_ui_ctx
    ctx.strokeStyle = @color
    ctx.strokeRect(@x - 2, @y - 2, 5, 5)

class PointWidget extends UIPoint
  @widgets = []

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

    @info_x = row.insertCell(1)
    @info_x.textContent = @x

    @info_y = row.insertCell(2)
    @info_y.textContent = @y

    @move_perc_cell = row.insertCell(3)
    @move_perc_cell.style.textAlign = 'right'
    @move_perc_cell.textContent = @move_perc.toFixed(2)

    @move_per_range_el = document.createElement('input')
    @move_per_range_el.type = 'range'
    @move_per_range_el.min = 0
    @move_per_range_el.max = 1
    @move_per_range_el.step = 0.05
    @move_per_range_el.value = @move_perc
    @move_per_range_el.addEventListener('input', @on_move_per_range_input)

    move_perc_adj_cell = row.insertCell(4)
    move_perc_adj_cell.appendChild(@move_per_range_el)

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
    ctx.fillRect(@x - 1, @y - 1, 3, 3)

class StochasticSierpinski
  constructor: (@context) ->

  init: () ->
    @running = false

    @steps_per_tick = 100

    @graph_canvas    = @context.getElementById('graph')
    @graph_ui_canvas = @context.getElementById('graph_ui')

    @graph_ctx    = @graph_canvas.getContext('2d', alpha: true)
    @graph_ui_ctx = @graph_ui_canvas.getContext('2d', alpha: true)

    @btn_reset = @context.getElementById('button_reset')
    @btn_step  = @context.getElementById('button_step')
    @btn_run   = @context.getElementById('button_run')

    @point_pos_table = @context.getElementById('point_pos_table')

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

    @btn_reset.addEventListener 'click', @on_reset
    @btn_step.addEventListener  'click', @on_step
    @btn_run.addEventListener   'click', @on_run

    @draw()

  resumable_reset: () =>
    @on_reset(true)

  on_reset: (restart_ok = false) =>
    was_running = @running
    @stop()

    @cur.move(
      @graph_ui_canvas.width / 2,
      @graph_ui_canvas.height / 2)

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

  step: =>
    for [0...@steps_per_tick]
      target = PointWidget.random_widget()
      @cur.move_towards_no_text_update target
      @cur.draw_graph(target)

    @cur.update_text()

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
