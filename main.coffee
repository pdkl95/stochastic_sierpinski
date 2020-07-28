APP = null

Array::flatten ?= () ->
  result = []
  for el in this
    if el instanceof Array
      result = result.concat(el.flatten())
    else
      result.push(el)
  result

Math.TAU ?= 2 * Math.PI

Object.values ?= (obj) ->
  Object.keys(obj).map( (x) -> obj[x] )

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

  @rgb_to_hsl: (rgb) ->
    r = rgb[0] / 255
    g = rgb[2] / 255
    b = rgb[2] / 255

    cmin = Math.min(r, g, b)
    cmax = Math.max(r, g, b)
    delta = cmax - cmin

    h = if delta == 0
      0
    else if cmax == r
      ((g - b) / delta) % 6
    else if cmax == g
      (b - r) / delta + 2
    else
      (r - g) / delta + 4

    h = Math.round(h * 60)
    h += 360 if h < 0

    l = (cmax + cmin) / 2

    s = if delta == 0
      0
    else
      delta / (1 - Math.abs(2 * l - 1))

    s = +(s * 100).toFixed(1)
    l = +(l * 100).toFixed(1)

    [h, s, l]

  @blend_rgb: (args...) ->
    total = args.reduce( (acc, cur) ->
       acc[0] += cur[0]
       acc[1] += cur[1]
       acc[2] += cur[2]
       acc )

    len = args.length
    [ total[0] // len,
      total[1] // len,
      total[2] // len ]

  @blend_hsl: (a_hsl, b_hsl) ->
    ah = a_hsl[0]
    bh = b_hsl[0]
    bh += 360 if bh < ah
    hdelta = bh - ah
    h = ah + (hdelta / 2)
    h -= 360 if h >= 360

    [ h,
      (a_hsl[1] + b_hsl[1]) // 2,
      (a_hsl[2] + b_hsl[2]) // 2 ]

  @blend_hsl_from_rgb: (a_rgb, b_rgb) ->
    a_hsl = Color.rgb_to_hsl(a_rgb)
    b_hsl = Color.rgb_to_hsl(b_rgb)
    @blend_hsl(a_hsl, b_hsl)

class Point
  constructor: (@name, x, y, @move_perc = 0.5) ->
    x ?= APP.graph_ui_canvas.width / 2
    y ?= APP.graph_ui_canvas.height / 2

    @el_id = @name.toLowerCase()
    @info_x_id = 'point_' + @el_id + '_x'
    @info_y_id = 'point_' + @el_id + '_y'

    @move_perc_mode = true

    @build()

    @move x, y

  build: ->

  update_text: () ->
    @info_x_cell.textContent = @ix if @info_x_cell
    @info_y_cell.textContent = @iy if @info_y_cell

  set_x: (x) =>
    @x = x
    @ix = Math.floor(@x)

  set_y: (y) =>
    @y = y
    @iy = Math.floor(@y)

  move_no_text_update: (x, y) ->
    @x = x
    @y = y
    @ix = Math.floor(@x)
    @iy = Math.floor(@y)

  move: (x, y) ->
    @move_no_text_update(x, y)
    @update_text()

  move_perc_towards: (target, perc = target.move_perc) ->
    dx = target.x - (@x)
    dy = target.y - (@y)
    @move(@x + dx * perc, @y + dy * perc)

  move_perc_towards_no_text_update: (target, perc = target.move_perc) ->
    dx = target.x - (@x)
    dy = target.y - (@y)
    @move_no_text_update(@x + dx * perc, @y + dy * perc)

  move_absolute_towards_no_text_update: (target, dist = target.move_perc) ->
    dist *= APP.move_absolute_magnitude
    dx = target.x - (@x)
    dy = target.y - (@y)
    mag = Math.sqrt(dx*dx + dy*dy)
    norm_x = dx / mag
    norm_y = dy / mag
    @move_no_text_update(@x + norm_x * dist, @y + norm_y * dist)

  distance: (other) ->
    dx = @x - other.x
    dy = @y - other.y
    Math.sqrt((dx * dx) + (dy * dy))

class UIPoint extends Point
  constructor: (hue, args...) ->
    @set_color_hue(hue)
    super args...

  update_color_alpha_from_color: () ->
    @set_opacity(APP.option.draw_opacity.value)

  set_color_hue: (hue) ->
    @set_color(Color.hsl_to_hexrgb(hue / 360, 1.0, 0.5))

  set_color: (color) ->
    @color = color
    @update_color_alpha_from_color()
    APP.cur?.reset_color_cache()

  set_alpha: (alpha) ->
    @color_alpha = Color.hexrgb_and_alpha_to_rgba_str(@color, alpha)

  set_opacity: (opacity) ->
    @set_alpha(opacity / 100)

  draw_ui: () ->
    ctx = APP.graph_ui_ctx
    ctx.strokeStyle = @color
    ctx.strokeRect(@x - 2, @y - 2, 5, 5)

  move_perc_range_el_init: ->
    @set_move_range(0, 100)
    @move_perc_range_el.value = @move_perc * 100
    @move_perc_range_el.addEventListener('input', @on_move_per_range_input)

  set_move_range: (min = 0, max = 100, step = 5) ->
    @move_perc_range_el.min = min
    @move_perc_range_el.max = max
    @move_perc_range_el.step = step
    if @option? and @option.move_proc?
      value = @option.move_proc.get()
      value = min if value < min
      value = max if value > max
      @option.move_proc.set_range(min, max)
      @option.move_proc.set(value)

  on_move_perc_option_change: (value) =>
    @set_move_perc(value)
    APP.resumable_reset()

  on_move_per_range_input: (event) =>
    @set_move_perc(event.target.value)
    APP.resumable_reset()

  set_move_perc_range: (newvalue) ->
    if @move_perc_range_el?
      step = @move_perc_range_el.step
      rounded = Math.round(newvalue / step) * step
      @move_perc_range_el.value = rounded

  set_move_perc: (newvalue) ->
    @move_perc = newvalue / 100.0
    newvalue = @move_perc * 100
    @option.move_perc.set(newvalue)
    @set_move_perc_range(newvalue)

  set_move_perc_mode: (newvalue) ->
    @move_perc_mode = newvalue
    @option.move_perc_mode.set(@move_perc_mode)

class PointWidget extends UIPoint
  @is_name_used: (name) ->
    for w in APP.points
      return true if w.name == name
    return false

  @next_name: () ->
    for code in [65..90]
      str = String.fromCharCode(code)
      unless PointWidget.is_name_used(str)
        return str

    alert('sorry, cannot generate more than 26 point names')
    throw 'cannot generate a unique point name'

  @create: (opt = {}) ->
    opt.name ?= PointWidget.next_name()
    opt.hue  ?= Math.random() * 360
    opt.move_perc ?= 0.5
    opt.x ?= APP.random_x()
    opt.y ?= APP.random_y()

    new PointWidget(opt.hue, opt.name, opt.x, opt.y, opt.move_perc)

  constructor: (args...) ->
    super args...
    APP.attach_point(this)

  build: ->
    @draw_highlight = false

    @row = APP.point_pos_table.insertRow(-1)

    @namecell = @row.insertCell(0)
    @set_name(@name)

    @color_selector_el = APP.create_input_element('color')
    @color_selector_el.value = @color
    @color_selector_el.addEventListener('change', @on_color_change)

    color_selector_cell = @row.insertCell(1)
    color_selector_cell.appendChild(@color_selector_el)

    @info_x_cell = @row.insertCell(2)
    @info_y_cell = @row.insertCell(3)
    @move_perc_cell = @row.insertCell(4)

    @option =
      x: NumberUIOption.create(@info_x_cell, "#{@info_x_id}_option", @x, @on_x_change)
      y: NumberUIOption.create(@info_y_cell, "#{@info_y_id}_option", @y, @on_y_change)
      move_perc: NumberUIOption.create(@move_perc_cell, "point_#{@el_id}_move_perc_option",
        @move_perc * 100, @on_move_perc_option_change)

    @move_perc_range_el = APP.create_input_element('range')
    @move_perc_range_el_init()

    move_perc_adj_cell = @row.insertCell(5)
    move_perc_adj_cell.appendChild(@move_perc_range_el)

    move_mode_cell = @row.insertCell(6)
    move_mode_cell.classList.add('move_mode')
    @option.move_perc_mode = BoolUIOption.create(move_mode_cell, "point_#{name}_move_mode", @move_perc_mode, @on_move_perc_mode_change)

  on_x_change: (value) =>
    @set_x(value)
    APP.resumable_reset()

  on_y_change: (value) =>
    @set_y(value)
    APP.resumable_reset()

  on_move_perc_mode_change: (value) =>
    @move_perc_mode = value
    APP.resumable_reset()

  update_text: ->
    @option.x.set(@ix)
    @option.y.set(@iy)

  set_name: (name) ->
    @name = name
    @namecell.textContent = @name

  set_color: (color) ->
    super(color)
    @color_selector_el.value = @color if @color_selector_el?

  on_color_change: (event) =>
    @set_color(event.target.value)
    APP.resumable_reset()

  highlight: () ->
    @row.classList.add('highlight')
    oldval = @draw_highlight
    @draw_highlight = true
    return (oldval != @draw_highlight)

  unhighlight: () ->
    @row.classList.remove('highlight')
    oldval = @draw_highlight
    @draw_highlight = false
    return (oldval != @draw_highlight)

  draw_ui: () ->
    if @draw_highlight
      ctx = APP.graph_ui_ctx
      ctx.save()
      ctx.strokeStyle = '#F97570'
      ctx.fillStyle   = '#FEFFC6'
      ctx.setLineDash([4])
      ctx.beginPath()
      ctx.arc(@x, @y, 15, 0, Math.TAU, false)
      ctx.fill()
      ctx.stroke()
      ctx.restore()

    super

  save: () ->
    opt =
      name:      @name
      x:         @x
      y:         @y
      move_perc: @option.move_perc.get()
      move_mode: if @move_perc_mode then 'percent' else 'absolute'
      color:     @color

  load: (opt) ->
    if opt.name?
      @set_name(opt.name)

    if opt.x? and opt.y?
      @move(opt.x, opt.y)

    if opt.move_perc?
      if 0.0 < opt.move_perc < 1.0
        opt.move_perc *= 100
      @set_move_perc(opt.move_perc)

    if opt.move_mode?
      switch opt.move_mode
        when 'percent'  then @set_move_perc_mode(true)
        when 'absolute' then @set_move_perc_mode(false)

    if opt.color?
      @set_color(opt.color)

    APP.resumable_reset()

  destroy: () ->
    APP.detach_point(this)

    for opt_name, opt of @option
      opt.destroy()

    @color_selector_el.remove()
    @move_perc_range_el.remove()
    @row.remove()

class DrawPoint extends UIPoint
  prev_target: [null, null, null]
  restricted:
    single_origin: []
    double_origin: []

  constructor: (name) ->
    super '0', name

    @movement_from_origin = true

    @restrictions = new TargetRestriction(APP.context)

    @set_color('#000000')
    @set_draw_style(@option.draw_style.get())
    @set_data_source('dest')

  build: ->
    @info_x_cell = APP.context.getElementById(@info_x_id)
    @info_y_cell = APP.context.getElementById(@info_y_id)

    @btn_set_all_points = APP.context.getElementById('set_all_points')
    @move_perc_range_el = APP.context.getElementById('all_points_move_perc_range')
    @move_perc_range_el_init()

    @option =
      move_perc: new NumberUIOption('all_points_move_perc_option',  @move_perc * 100, @on_move_perc_option_change)
      draw_style: new EnumUIOption('draw_style', 'color_blend_prev_color', @set_draw_style)
      data_source: new EnumUIOption('movement_data_source', 'dest', @set_data_source)

    @btn_set_all_points.addEventListener('click', @on_set_all_points)

  on_set_all_points: (event) =>
    APP.set_all_points_move_perc(@move_perc * 100)
    APP.resumable_reset()

  reset_color_cache: ->
    @color_avg = {}
    @prev_color_blend = Color.hexrgb_to_rgb(@color)

  blend_target_colors: (a, b) ->
    a_rgb = Color.hexrgb_to_rgb(a.color)
    b_rgb = Color.hexrgb_to_rgb(b.color)
    blend = Color.blend_rgb(a_rgb, b_rgb)
    "rgba(#{blend[0]},#{blend[1]},#{blend[2]},#{@alpha})"

  get_color_mono: ->
    @color_alpha

  get_color_target: (target) ->
    target.color_alpha

  get_color_blend_prev1: ->
    b = @prev_target[1]
    a = @prev_target[0]
    return a.color_alpha unless b?
    name = a.name + b.name
    @color_avg[name] ?= @blend_target_colors(a, b)

  get_color_blend_prev2: (target) ->
    t = Color.hexrgb_to_rgb(target.color)
    p = @prev_color_blend
    @prev_color_blend = Color.blend_rgb(t, p)
    c = "rgba(#{@prev_color_blend[0]},#{@prev_color_blend[1]},#{@prev_color_blend[2]},#{@alpha})"
    #console.log(t, p, @prev_color_blend, c)
    c

  set_data_source: (src) =>
    @option.data_source.set(src)
    @single_step = switch @option.data_source.get()
      when 'dest' then @single_step_destination
      when 'orig' then @single_step_origin
      else
        @single_step_destination
    APP.resumable_reset()

  set_draw_style: (mode) =>
    @option.draw_style.set(mode)
    @get_current_color = switch @option.draw_style.get()
      when 'mono'                    then @get_color_mono
      when 'color_target'            then @get_color_target
      when 'color_blend_prev_target' then @get_color_blend_prev1
      when 'color_blend_prev_color'  then @get_color_blend_prev2
      else
        @get_color_mono

  set_opacity: (opacity) ->
    @opacity = opacity
    @alpha   = opacity / 100
    super(opacity)

  target_chosen_twice: ->
    @prev_target[0] == @prev_target[1]

  current_restricted_choices: ->
    if @restrictions.using_double() and @target_chosen_twice()
      @restricted.double_origin
    else
      @restricted.single_origin

  filtered_choices: (type) ->
    value_getter = "value_#{type}"

    len  = num_points = APP.points.length
    last = len - 1

    choices = []

    unless @restrictions.option.self[value_getter]
      choices.push(0)
    len -= 1

    if len % 2 == 1
      len -= 1
      unless @restrictions.option.opposite[value_getter]
        choices.push(parseInt(last / 2) + 1)

    neighbor = 1
    while len >= 2
      [p, n] = @restrictions.neighbor(neighbor)

      unless p[value_getter]
        choices.push(p.offset + num_points)

      unless n[value_getter]
        choices.push(n.offset)

      len -= 2
      neighbor += 1

    choices

  update_point_list_metadata: ->
    return if APP.points.length < 3
    @restrictions.set_enabled(APP.points.length)
    @restricted.single_origin = @filtered_choices('single')
    @restricted.double_origin = @filtered_choices('double')
    @prev_target[0] = @prev_target[1] = APP.points[0]

  random_point: ->
    choices = @current_restricted_choices()
    choice = choices[ parseInt(Math.random() * choices.length) ]
    prev_idx = APP.points.indexOf(@prev_target[0])
    idx = (choice + prev_idx) % APP.points.length

    p = APP.points[idx]
    @prev_target[2] = @prev_target[1]
    @prev_target[1] = @prev_target[0]
    @prev_target[0] = p
    p

  draw_graph: (target) ->
    ctx = APP.graph_ctx
    ctx.fillStyle = @get_current_color(target)
    ctx.fillRect(@x, @y, 1, 1)
    return null

  single_step_origin: ->
    target = @random_point()
    return false unless target?
    origin = @prev_target[1]
    if origin.move_perc_mode
      @move_perc_towards_no_text_update(target, origin.move_perc)
    else
      @move_absolute_towards_no_text_update(target, origin.move_perc)
    @draw_graph(target)
    return true

  single_step_destination: ->
    target = @random_point()
    return false unless target?
    if target.move_perc_mode
      @move_perc_towards_no_text_update(target, target.move_perc)
    else
      @move_absolute_towards_no_text_update(target, target.move_perc)
    @draw_graph(target)
    return true

class TargetRestrictionOption
  constructor: (@context, @offset, @name) ->
    selector = "#restrict_table .#{@name}"
    @column_cells    = @context.querySelectorAll(selector)

    single_selector = "#{selector}.single input[type=\"checkbox\"]"
    double_selector = "#{selector}.double input[type=\"checkbox\"]"
    @checkbox_single = @context.querySelector(single_selector)
    @checkbox_double = @context.querySelector(double_selector)

    @reset()

    @checkbox_single.addEventListener 'change', @on_change_single
    @checkbox_double.addEventListener 'change', @on_change_double

  reset: ->
    @set_single(false)
    @set_double(false)

  set_column_cells: (state) ->
    for cell in @column_cells
      cell.style.display = state

  enable: ->
    @enabled = true
    @set_column_cells('table-cell')

  disable: ->
    @enabled = false
    @set_column_cells('none')

  set_single: (value) ->
    @value_single = value
    @checkbox_single.checked = @value_single
    APP.update_metadata_and_reset()

  set_double: (value) ->
    @value_double = value
    @checkbox_double.checked = @value_double
    APP.update_metadata_and_reset()

  on_change_single: (event) =>
    @set_single(event.target.checked)

  on_change_double: (event) =>
    @set_double(event.target.checked)

class TargetRestriction
  constructor: (@context) ->
    @option =
      prev: [
        new TargetRestrictionOption(@context, -1, 'prev1'),
        new TargetRestrictionOption(@context, -2, 'prev2'),
        new TargetRestrictionOption(@context, -3, 'prev3'),
      ]
      self: new TargetRestrictionOption(@context,  0, 'self')
      next: [
        new TargetRestrictionOption(@context,  1, 'next1'),
        new TargetRestrictionOption(@context,  2, 'next2'),
        new TargetRestrictionOption(@context,  3, 'next3')
      ]
      opposite: new TargetRestrictionOption(@context,  4, 'opposite'),

    @options = Object.values(@option).flatten()

    @by_name = {}
    for o in @options
      @by_name[o.name] = o

  find: (name) ->
    if @by_name[name]?
      @by_name[name]
    else
      console.log("no such restriction named '#{name}'")
      null

  set_enabled: (n) ->
    o.disable() for o in @options

    @option.self.enable()
    n -= 1

    if n % 2 == 1
      @option.opposite.enable()
      n -= 1

    neighbor = 1
    while n >= 2
      [prev, next] = @neighbor(neighbor)
      prev.enable()
      next.enable()

      n -= 2
      neighbor += 1

    null

  using_double: ->
    for o in @options
      return true  if o.enabled and o.value_double
    return false

  restricted_single: ->
    @options.filter( (o) -> o.value_single )

  restricted_double: ->
    @options.filter( (o) -> o.value_double )

  neighbor: (n) ->
    [@by_name["prev#{n}"], @by_name["next#{n}"]]

  save: ->
    opt =
      single: @restricted_single().map( (x) -> x.name )
      double: @restricted_double().map( (x) -> x.name )

  load: (opt) ->
    o.reset() for o in opt

    if opt.single?
      for name in opt.single
        @find(name)?.set_single(true)

    if opt.double?
      for name in opt.double
        @find(name)?.set_double(true)

    APP.update_metadata_and_reset()

class UIOption
  constructor: (@id, @default, @on_change_callback) ->
    if @id instanceof Element
      @el = @id
      @id = @el.id
    else
      @el = APP.context.getElementById(@id)

    @set(@default)
    @el.addEventListener('change', @on_change)

  on_change: (event) =>
    @set(@get(event.target))
    @on_change_callback(@value) if @on_change_callback?

  destroy: ->
    @el.remove() if @el?
    @el = null

class BoolUIOption extends UIOption
  @create: (parent, @id, rest...) ->
    opt = new BoolUIOption(APP.create_input_element('checkbox', @id), rest...)
    parent.appendChild(opt.el)
    opt

  get: (element = @el) ->
    element.checked

  set: (bool_value) ->
    @value = !!bool_value
    @el.checked = @value

class NumberUIOption extends UIOption
  @create: (parent, @id, rest...) ->
    opt = new NumberUIOption(APP.create_input_element('number', @id), rest...)
    parent.appendChild(opt.el)
    opt

  get: (element = @el) ->
    element.value

  set: (number_value) ->
    @value = parseInt(number_value)
    @el.value = @value

  set_range: (min, max, step = 1) ->
    @el.min = min
    @el.max = max
    @el.step = step

class EnumUIOption extends UIOption
  get: (element = @el) ->
    element.value

  find_option_by_value: (enum_value) ->
    for opt in @el.options
      return opt if opt.value == enum_value
    return null

  set: (enum_value) ->
    opt = @find_option_by_value(enum_value)
    @el.value = opt.value if opt?
    @value = @el.value

class StochasticSierpinski
  MIN_POINTS: 3
  MAX_POINTS: 8
  REG_POLYGON_MARGIN: 10
  NEARBY_RADIUS: 8

  points: []
  move_absolute_magnitude: 100

  constructor: (@context) ->

  init: () ->
    @running = false

    @step_count = 0

    @steps_per_frame_el = @context.getElementById('steps_per_frame')

    @graph_wrapper   = @context.getElementById('graph_wrapper')
    @graph_canvas    = @context.getElementById('graph')
    @graph_ui_canvas = @context.getElementById('graph_ui')

    @graph_ctx    = @graph_canvas.getContext('2d', alpha: true)
    @graph_ui_ctx = @graph_ui_canvas.getContext('2d', alpha: true)

    @btn_reset     = @context.getElementById('button_reset')
    @btn_step      = @context.getElementById('button_step')
    @btn_multistep = @context.getElementById('button_multistep')
    @btn_run       = @context.getElementById('button_run')

    @btn_create_png = @context.getElementById('button_create_png')
    @btn_save_url   = @context.getElementById('button_save_url')
    @btn_save       = @context.getElementById('button_save')
    @btn_load       = @context.getElementById('button_load')

    @total_steps_cell = @context.getElementById('total_steps')
    @point_pos_table  = @context.getElementById('point_pos_table')

    @num_points_el = @context.getElementById('num_points')

    @btn_move_all_reg_polygon = @context.getElementById('move_all_reg_polygon')
    @btn_move_all_random      = @context.getElementById('move_all_random')

    @option =
      canvas_width:   new NumberUIOption('canvas_width',   420, @on_canvas_hw_change)
      canvas_height:  new NumberUIOption('canvas_height',  420, @on_canvas_hw_change)
      draw_opacity:   new NumberUIOption('draw_opacity',    35, @on_draw_opacity_change)
      move_range_min: new NumberUIOption('move_range_min',   0, @on_move_range_change)
      move_range_max: new NumberUIOption('move_range_max', 100, @on_move_range_change)

    @serializebox        = @context.getElementById('serializebox')
    @serializebox_title  = @context.getElementById('serializebox_title')
    @serializebox_text   = @context.getElementById('serializebox_text')
    @serializebox_action = @context.getElementById('serializebox_action')
    @serializebox_cancel = @context.getElementById('serializebox_cancel')

    @cur = new DrawPoint('Cur')

    @set_ngon(3)

    @set_steps_per_frame(100)

    @num_points_el.addEventListener 'input', @on_num_points_input
    @steps_per_frame_el.addEventListener 'input', @on_steps_per_frame_input

    @btn_reset.addEventListener      'click', @on_reset
    @btn_step.addEventListener       'click', @on_step
    @btn_multistep.addEventListener  'click', @on_multistep
    @btn_run.addEventListener        'click', @on_run

    @context.addEventListener 'keydown', @on_keydown

    @btn_create_png.addEventListener 'click', @on_create_png
    @btn_save_url.addEventListener 'click', @on_save_url
    @btn_save.addEventListener 'click', @on_save
    @btn_load.addEventListener 'click', @on_load

    @btn_move_all_reg_polygon.addEventListener 'click', @on_move_all_reg_polygon
    @btn_move_all_random.addEventListener 'click', @on_move_all_random

    @serializebox_action.addEventListener 'click', @on_serializebox_action
    @serializebox_cancel.addEventListener 'click', @on_serializebox_cancel

    @graph_ui_canvas.addEventListener 'mousedown', @on_mousedown
    @graph_ui_canvas.addEventListener 'mouseup',   @on_mouseup
    @graph_ui_canvas.addEventListener 'mousemove', @on_mousemove

    @graph_wrapper.addEventListener 'mouseenter', @on_mouseenter
    @graph_wrapper.addEventListener 'mouseleave', @on_mouseleave

    for i in [0..document.styleSheets.length]
      s = document.styleSheets[i]
      if s?.title == 'app_stylesheet'
        @app_stylesheet = s
        break

    if @app_stylesheet?
      for i in [0..@app_stylesheet.cssRules.length]
        r = @app_stylesheet.cssRules[i]
        if r?.selectorText == '.canvas_size'
          @canvas_size_rule = r
          break

      if @canvas_size_rule?
        @graph_wrapper_observer = new MutationObserver(@on_graph_wrapper_mutate)
        @graph_wrapper_observer.observe(@graph_wrapper, { attributes: true })

    @clear_update_and_draw()

  create_element: (name, id = null) ->
    el = @context.createElement(name)
    el.id = id if id?
    el

  create_input_element: (type, id = null) ->
    el = @create_element('input', id)
    el.type = type
    el

  on_move_range_change: =>
    min = @option.move_range_min.get()
    max = @option.move_range_max.get()
    @cur.set_move_range(min, max)
    for p in @points
      p.set_move_range(min, max)
    @resumable_reset()

  on_draw_opacity_change: =>
    o = @option.draw_opacity.value
    @cur.set_opacity(o)
    for p in @points
      p.set_opacity(o)

  clear_update_and_draw: ->
    @update_info_elements()
    @clear_graph_canvas()
    @redraw_ui()

  on_mouseenter: =>
    @graph_wrapper.classList.add('resizable')

  on_mouseleave: =>
    @graph_wrapper.classList.remove('resizable')

  on_graph_wrapper_mutate: (event) =>
    if @graph_wrapper.offsetWidth != @graph_ui_canvas.width or @graph_wrapper.offsetHeight != @graph_ui_canvas.height
      @resize_graph(@graph_wrapper.offsetWidth, @graph_wrapper.offsetHeight)

  clamp_points_to_canvas: ->
    [width, height] = APP.max_xy()

    for p in APP.points
      p.x = 0 if p.x < 0
      p.y = 0 if p.y < 0
      p.x = width  - 1 if p.x >= width
      p.y = height - 1 if p.y >= height

  resize_graph: (w, h) ->
    @graph_canvas.width  = w
    @graph_canvas.height = h
    @graph_ui_canvas.width  = w
    @graph_ui_canvas.height = h
    @canvas_size_rule.style.width  = "#{w}px"
    @canvas_size_rule.style.height = "#{h}px"
    @option.canvas_width.set(w)
    @option.canvas_height.set(h)

    @clamp_points_to_canvas()
    @resumable_reset()

  on_canvas_hw_change: =>
    @resize_graph(@option.canvas_width.value, @option.canvas_height.value)

  attach_point: (point) ->
    @points.push(point)
    @cur.update_point_list_metadata()

  detach_point: (point) ->
    idx = @points.indexOf(point)

    if idx > -1
      @points.splice(idx, 1)
      @cur.update_point_list_metadata()

    APP.resumable_reset()

  add_point: () ->
    if @points.length < APP.MAX_POINTS
      PointWidget.create()
      @resumable_reset()

  remove_point: () ->
    len = @points.length
    if len > APP.MIN_POINTS
      @points[len - 1].destroy()

  set_num_points: (n) ->
    return unless n >= @MIN_POINTS and n <= @MAX_POINTS

    diff = n - @points.length
    @add_point() for [0...diff] if diff > 0

    diff = @points.length - n
    @remove_point() for [0...diff] if diff > 0

    @num_points_el.value = @points.length;

  recolor_periodic_hue: (step, start = 0.0) ->
    hue = start
    for p in @points
      p.set_color_hue(hue)
      hue += step

  recolor_equidistant_hue: () ->
    @recolor_periodic_hue(360.0 / @points.length)

  set_ngon: (n, recolor = true) ->
    @set_num_points(n)
    @on_move_all_reg_polygon()
    @recolor_equidistant_hue() if recolor

  on_num_points_input: (event) =>
    @set_ngon(event.target.value)

  set_all_points_move_perc: (value) ->
    for p in @points
      p.set_move_perc(value)

  on_steps_per_frame_input: (event) =>
    @set_steps_per_frame(event.target.value)

  set_steps_per_frame: (int_value) ->
    @steps_per_frame = parseInt(int_value)

    if @steps_per_frame < 1
      @steps_per_frame = 1

    @btn_multistep.textContent = "Step #{@steps_per_frame}x"
    if @steps_per_frame == 1
      @steps_per_frame_el.value = 0
      @btn_multistep.disabled = true
    else
      @steps_per_frame_el.value = @steps_per_frame
      @btn_multistep.disabled = false

  on_create_png: =>
    dataurl = @graph_canvas.toDataURL('png')
    window.open(dataurl, '_blank')

  show_serializebox: (title, text, action_callback) ->
    @serializebox_title.textContent = title
    @serializebox_action.textContent = title

    if text?
      @serializebox_text.value = text
    else
      @serializebox_text.value = ''

    if action_callback?
      @serializebox_action.style.display = 'inline-block'
      @serializebox_action_callback = action_callback
      @serializebox_cancel.textContent = 'Cancel'
    else
      @serializebox_action.style.display = 'none'
      @serializebox_cancel.textContent = 'Close'

    @serializebox.style.display = 'block'

  hide_serializebox: ->
    @serializebox.style.display = 'none'

  on_serializebox_action: =>
    if @serializebox_action_callback?
      @serializebox_action_callback(@serializebox_text.value)

    @hide_serializebox()

  on_serializebox_cancel: =>
    @hide_serializebox()

  serialize: ->
    opt =
      points: @points.map( (x) -> x.save() )
      restrictions: @cur.restrictions.save()
      options:
        canvas_width:  @option.canvas_width.value
        canvas_height: @option.canvas_height.value
        draw_opacity:  @option.draw_opacity.value
        draw_style:    @cur.option.draw_style.get()
        data_source:   @cur.option.data_source.get()
        all_points_move_perc: @cur.option.move_perc.get()
        move_absolute_magnitude: @move_absolute_magnitude
        move_range_min: @option.move_range_min.get()
        move_range_max: @option.move_range_max.get()

    JSON.stringify(opt)

  deserialize: (text) =>
    opt = JSON.parse(text)

    if opt.options?
      if opt.options.canvas_width? and opt.options.canvas_width?
        @resize_graph(opt.options.canvas_width, opt.options.canvas_width)

      if opt.options.draw_opacity?
        @option.draw_opacity.set(opt.options.draw_opacity)

      if opt.options.draw_style?
        @cur.set_draw_style(opt.options.draw_style)

      if opt.options.data_source?
        @cur.set_data_source(opt.options.data_source)

      if opt.options.move_range_min?
        @option.move_range_min.set(opt.options.move_range_min)

      if opt.options.move_range_max?
        @option.move_range_max.set(opt.options.move_range_max)

      if opt.options.move_range_min? or opt.options.move_range_max?
        @on_move_range_change()

      if opt.options.all_points_move_perc?
        @cur.set_move_perc(opt.options.all_points_move_perc)

      if opt.options.move_absolute_magnitude?
        @move_absolute_magnitude = opt.options.move_absolute_magnitude

    if opt.points?
      @set_num_points(opt.points.length)
      for p, i in opt.points
        @points[i].load(p)

    if opt.restrictions?
      @cur.restrictions.load(opt.restrictions)
    
  on_save: =>
    @show_serializebox('Save', @serialize(), null)

  on_load: =>
    @show_serializebox('Load', null, @deserialize)

  on_save_url: =>
    hash = @serialize()
    document.location = "##{hash}"

  on_move_all_reg_polygon: =>
    len = @points.length

    [maxx, maxy] = @max_xy()
    minside = Math.min(maxx, maxy)
    cx = maxx / 2
    cy = maxy / 2
    mincxy = Math.min(cx, cy)
    r = mincxy - @REG_POLYGON_MARGIN
    theta = (Math.PI * 2) / len

    rotate = -Math.PI/2

    switch len
      when 3
        side = minside - (2 * @REG_POLYGON_MARGIN)
        height = side * (Math.sqrt(3) / 2)
        tri_adj = (minside - height) / 2
        cy += tri_adj * 1.5
        r *= 1.12

      when 4
        rotate += Math.PI/4
        r = Math.sqrt((r * r) * 2)

    for p, i in @points
      x = parseInt(r * Math.cos(rotate + theta * i))
      y = parseInt(r * Math.sin(rotate + theta * i))
      p.move(cx + x, cy + y)

    @resumable_reset()

  on_move_all_random: () =>
    for p in @points
      p.move(@random_x(), @random_y())

    @resumable_reset()

  random_x: =>
    parseInt(Math.random() * @graph_ui_canvas.width)

  random_y: =>
    parseInt(Math.random() * @graph_ui_canvas.height)

  max_xy: =>
    [@graph_ui_canvas.width, @graph_ui_canvas.height]

  update_info_elements: () ->
    @total_steps_cell.textContent = @step_count
    @cur?.update_text()

  event_to_canvas_loc: (event) ->
    return
      x: event.layerX
      y: event.layerY

  is_inside_ui: (loc) ->
    return (
      (0 <= loc.x <= @graph_ui_canvas.width) and
      (0 <= loc.y <= @graph_ui_canvas.height))

  nearby_points: (loc) ->
    @points.filter (p) =>
      p.distance(loc) < @NEARBY_RADIUS

  first_nearby_point: (loc) ->
    nearlist = @nearby_points(loc)
    if nearlist?
      nearlist[0]
    else
      null

  unhighlight_all: () ->
    changed = false
    for p in @points
      changed = true if p.unhighlight()
    return changed

  on_mousedown: (event) =>
    @unhighlight_all()
    loc = @event_to_canvas_loc(event)
    p = @first_nearby_point(loc)
    if p?
      @dnd_target = p
      p.highlight()

  on_mouseup: (event) =>
    if @dnd_target?
      loc = @event_to_canvas_loc(event)
      if @is_inside_ui(loc)
        @dnd_target.move(loc.x, loc.y)
        @redraw_ui()
        @resumable_reset()

      @dnd_target = null

  on_mousemove: (event) =>
    loc = @event_to_canvas_loc(event)
    if @dnd_target?
      if @is_inside_ui(loc)
        @dnd_target.move(loc.x, loc.y)
        @redraw_ui()
        @resumable_reset()
    else
      redraw = @unhighlight_all()

      p = @first_nearby_point(loc)
      if p?
        redraw = true if p.highlight()

      @redraw_ui() if redraw

  resumable_reset: () =>
    @on_reset(true)

  update_metadata_and_reset: ->
    @cur?.update_point_list_metadata()
    @on_reset(true)

  clear_graph_canvas: () ->
    @graph_ctx.clearRect(0, 0, @graph_canvas.width, @graph_canvas.height)
    @graph_ctx.fillStyle = '#fff'
    @graph_ctx.fillRect(0, 0, @graph_canvas.width, @graph_canvas.height)

  on_reset: (restart_ok = false) =>
    was_running = @running
    @stop()

    if @cur?
      @cur.move(
        @graph_ui_canvas.width / 2,
        @graph_ui_canvas.height / 2)
      @cur.reset_color_cache()

    @step_count = 0

    @clear_update_and_draw()

    @start() if restart_ok and was_running

  on_step: =>
    if @running
      @stop()
    else
      @step()

  on_multistep: =>
    if @running
      @stop()
    else
      @multistep()

  on_run: =>
    if @running
      @stop()
    else
      @start()

  start: =>
    @running = true
    @btn_run.textContent = 'Pause'
    @btn_run.classList.remove('paused')
    @btn_run.classList.add('running')
    @schedule_next_frame()

  stop: =>
    @running = false
    @btn_run.textContent = 'Run'
    @btn_run.classList.remove('running')
    @btn_run.classList.add('paused')

  single_step: ->
    if @cur.single_step()
      @step_count += 1
    return null

  step: (num_steps = 1) =>
    @single_step() for [0...num_steps]

    @update_info_elements()
    @redraw_ui()
    return null

  multistep: ->
    @step(@steps_per_frame)
    return null

  redraw_ui: =>
    @graph_ui_ctx.clearRect(0, 0, @graph_ui_canvas.width, @graph_ui_canvas.height)

    @cur?.draw_ui()

    for p in @points
      p.draw_ui()

    return null

  update: =>
    @frame_is_scheduled = false
    @multistep()
    @schedule_next_frame() if @running
    return null

  schedule_next_frame: () ->
    unless @frame_is_scheduled
      @frame_is_scheduled = true
      window.requestAnimationFrame(@update)

    return null

  on_keydown: (event) =>
    switch event.key
      when "Enter"         then @on_run()
      when "Escape", "Esc" then @stop()
      when "r", "R"        then @resumable_reset()
      when "p", "P"        then @on_create_png()
      when "s", "S"        then @on_save()
      when "l", "L"        then @on_load()

document.addEventListener 'DOMContentLoaded', =>
  APP = new StochasticSierpinski(document)
  APP.init()

  if document.location.hash?.length > 1
    APP.deserialize(document.location.hash.slice(1))
