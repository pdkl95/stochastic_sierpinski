class Point
  constructor: (@app, @name, x, y) ->
    @el_id = @name.toLowerCase()
    @info_x = @app.context.getElementById('point_' + @el_id + '_x')
    @info_y = @app.context.getElementById('point_' + @el_id + '_y')

    @move x, y

    @move_perc = 0.5

  move: (x, y) ->
    @x = x
    @y = y
    @ix = Math.floor(@x)
    @iy = Math.floor(@y)
    @info_x.textContent = '' + @ix if @info_x
    @info_y.textContent = '' + @iy if @info_y

  move_towards: (other, perc = @move_perc) ->
    dx = other.x - (@x)
    dy = other.y - (@y)
    @move @x + dx * perc, @y + dy * perc

class UIPoint extends Point
  constructor: (hue, args...) ->
    @color       = 'hsl(' + hue + ', 100%, 50%)'
    @color_alpha = 'hsla(' + hue + ', 100%, 50%, ' + DrawPoint.ALPHA + ')'
    super args...

  draw_ui: () ->
    ctx = @app.graph_ui_ctx
    ctx.strokeStyle = @color
    ctx.strokeRect(@x - 2, @y - 2, 5, 5)

class PointWidget extends UIPoint
  constructor: (args...) ->
    super args...

    # build the widget UI

class DrawPoint extends UIPoint
  @ALPHA = '0.333'

  constructor: (args...) ->
    super args...
    @color = '#000'

  draw_graph: (target) ->
    ctx = @app.graph_ctx
    ctx.fillStyle = target.color_alpha
    ctx.fillRect(@x - 1, @y - 1, 3, 3)

class StochasticSierpinski
  constructor: (@context) ->
    @running = false

    @graph_canvas    = @context.getElementById('graph')
    @graph_ui_canvas = @context.getElementById('graph_ui')

    @graph_ctx    = @graph_canvas.getContext('2d', alpha: true)
    @graph_ui_ctx = @graph_ui_canvas.getContext('2d', alpha: true)

    @btn_reset = @context.getElementById('button_reset')
    @btn_step  = @context.getElementById('button_step')
    @btn_run   = @context.getElementById('button_run')

    @a = new PointWidget(  '0', this, 'A', 210,  20)
    @b = new PointWidget('120', this, 'B',  40, 300)
    @c = new PointWidget('240', this, 'C', 380, 300)
    @points = [@a, @b, @c]

    @cur  = new DrawPoint('0', this, 'Cur',  @a.x,   @a.y)

    @btn_reset.addEventListener 'click', @on_reset
    @btn_step.addEventListener  'click', @on_step
    @btn_run.addEventListener   'click', @on_run

    @draw()

  on_reset: =>
    @stop()
    @graph_ctx.clearRect(0, 0, @graph_canvas.width, @graph_canvas.height)

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

  random_point: ->
    rand = Math.random() * 3
    return @a if rand < 1
    return @b if rand < 2
    @c

  step: =>
    target = @random_point()
    @cur.move_towards target, 0.5
    @cur.draw_graph(target)

    @draw()

  draw: =>
    @graph_ui_ctx.clearRect(0, 0, @graph_ui_canvas.width, @graph_ui_canvas.height)

    @cur.draw_ui()

    for p in @points
      p.draw_ui()

  update: =>
    @step()
    @schedule_next_frame() if @running

  schedule_next_frame: () ->
    window.requestAnimationFrame(@update)

document.addEventListener 'DOMContentLoaded', =>
  new StochasticSierpinski(document)
