class Point
  constructor: (@app, @name, x, y) ->
    @id = name.toLowerCase()
    @info_x = app.context.getElementById('point_' + @id + '_x')
    @info_y = app.context.getElementById('point_' + @id + '_y')
    @move x, y

    @move_perc = 0.5

  move: (x, y) ->
    @x = x
    @y = y
    @ix = Math.floor(@x)
    @iy = Math.floor(@y)
    @info_x.textContent = @ix if @info_x
    @info_y.textContent = @iy if @info_y

  move_towards: (other, perc = @move_perc) ->
    dx = other.x - (@x)
    dy = other.y - (@y)
    @move @x + dx * perc, @y + dy * perc

class StochasticSierpinski
  constructor: (@context) ->
    @running = false

    @canvas = @context.getElementById('graph')
    @ctx    = @canvas.getContext('2d', alpha: false)

    @btn_reset = @context.getElementById('button_reset')
    @btn_step  = @context.getElementById('button_step')
    @btn_run   = @context.getElementById('button_run')

    @a = new Point(this, 'A', 210,  20)
    @b = new Point(this, 'B',  40, 300)
    @c = new Point(this, 'C', 380, 300)
    @points = [@a, @b, @c]

    @cur  = new Point(this, 'Cur',  @a.x,   @a.y)

    @btn_reset.addEventListener 'click', @on_reset
    @btn_step.addEventListener 'click', @on_step
    @btn_run.addEventListener 'click', @on_run

  on_reset: =>

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

  stop: =>
    @running = false
    @btn_run.textContent = 'Run'

  random_point: ->
    rand = Math.random() * 3
    return @aif rand < 1
      
    if rand < 2
      @b
    else
      @c

  step: =>
    target = @random_point()
    @cur.move_towards target, 0.5

document.addEventListener 'DOMContentLoaded', =>
  new StochasticSierpinski(document)
