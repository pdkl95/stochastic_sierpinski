APP = null

MAX_LARGE_DATA_SIZE = 255

Array::flatten ?= () ->
  result = []
  for el in this
    if el instanceof Array
      result = result.concat(el.flatten())
    else
      result.push(el)
  result

Array::shuffle = () ->
  this.slice(0).reduceRight(
    ((r,_,__,s) ->
      r.push(s.splice(0|Math.random()*s.length,1)[0])
      r),
    [])

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

  @srgb_to_linear: (x) ->
    x /= 255.0
    if x <= 0
      0
    else if x >= 1
      1
    else if x < 0.04045
      x / 12.92
    else
      Math.pow((x + 0.055) / 1.055, 2.4)

  @linear_rgb_to_luminance: (rl, gl, bl) ->
    (0.2126 * rl) + (0.7152 * gl) + (0.0722 * bl)

  @srgb_to_luminance: (r, g, b) ->
      rl = Color.srgb_to_linear(r)
      gl = Color.srgb_to_linear(g)
      bl = Color.srgb_to_linear(b)
      Color.linear_rgb_to_luminance(rl, gl, bl)

class Point
  constructor: (@name, x, y, @move_perc = APP.DEFAULT.move_perc) ->
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

  move_no_text_update_array: (coord) ->
    @x = coord[0]
    @y = coord[1]
    @ix = Math.floor(@x)
    @iy = Math.floor(@y)

  move: (x, y) ->
    @move_no_text_update(x, y)
    @update_text()

  move_perc_towards: (target, perc = target.move_perc) ->
    dx = target.x - (@x)
    dy = target.y - (@y)
    @move(@x + dx * perc, @y + dy * perc)

  coords_after_move_perc_towards_target: (target, perc = target.move_perc) ->
    dx = target.x - (@x)
    dy = target.y - (@y)
    [@x + dx * perc, @y + dy * perc]

  move_perc_towards_no_text_update: (target, perc = target.move_perc) ->
    @move_no_text_update_array(@coords_after_move_perc_towards_target(target, perc))

  coords_after_move_absolute_towards_target: (target, dist = target.move_perc) ->
    dist *= APP.move_absolute_magnitude
    dx = target.x - (@x)
    dy = target.y - (@y)
    mag = Math.sqrt(dx*dx + dy*dy)
    norm_x = dx / mag
    norm_y = dy / mag
    [@x + norm_x * dist, @y + norm_y * dist]

  move_absolute_towards_no_text_update: (target, dist = target.move_perc) ->
    @move_no_text_update_array(@coords_after_move_absolute_towards_target(target, dist))

  distance: (other) ->
    dx = @x - other.x
    dy = @y - other.y
    Math.sqrt((dx * dx) + (dy * dy))

  scale_width: (scale) ->
    @set_x(@x * scale)
    @update_text()

  scale_height: (scale) ->
    @set_y(@y * scale)
    @update_text()

  scale: (scale) ->
    @scale_width(scale, origin)

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
    @set_move_range()
    @move_perc_range_el.value = @move_perc * 100
    @move_perc_range_el.addEventListener('input', @on_move_per_range_input)

  set_move_range: (min = APP.option.move_range_min.get(), max = APP.option.move_range_max.get(), step = 5) ->
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

  save: (include_large_data = true) ->
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

  load_default_state: ->
    @set_move_perc(APP.DEFAULT.move_perc * 100)
    @set_move_perc_mode(true)

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
    @imgmask_defer_convert_img_to_bitmap = false
    @have_deferred_imgmask_bitmap_update = false

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

    @imgmask_img_hide_list = APP.context.querySelectorAll('.imgmask_img_hide')

    @imgmask_file               = APP.context.getElementById('imgmask_file')
    @imgmask_file_button        = APP.context.getElementById('imgmask_file_button')
    @imgmask_url                = APP.context.getElementById('imgmask_url')
    @imgmask_url_button         = APP.context.getElementById('imgmask_url_button')
    @imgmask_img_caption        = APP.context.getElementById('imgmask_img_caption')
    @imgmask_img_size_width     = APP.context.getElementById('imgmask_img_size_width')
    @imgmask_img_size_height    = APP.context.getElementById('imgmask_img_size_height')
    @imgmask_bitmap_caption     = APP.context.getElementById('imgmask_bitmap_caption')
    @imgmask_bitmap_size_width  = APP.context.getElementById('imgmask_bitmap_size_width')
    @imgmask_bitmap_size_height = APP.context.getElementById('imgmask_bitmap_size_height')

    @imgmask_img_ready = false

    @option =
      imgmask_enabled:    new BoolUIOption(  'imgmask_enabled',    APP.DEFAULT.imgmask.enabled,    @on_imgmask_enabled_change)
      imgmask_threshold:  new NumberUIOption('imgmask_threshold',  APP.DEFAULT.imgmask.threshold,  @on_imgmask_threshold_change)
      imgmask_oversample: new NumberUIOption('imgmask_oversample', APP.DEFAULT.imgmask.oversample, @on_imgmask_oversample_change)
      imgmask_scale_width:  new NumberUIOption('imgmask_scale_width',  APP.DEFAULT.imgmask.scale.width,  @on_imgmask_scale_change)
      imgmask_scale_height: new NumberUIOption('imgmask_scale_height', APP.DEFAULT.imgmask.scale.height, @on_imgmask_scale_change)
      imgmask_offset_x: new NumberUIOption('imgmask_offset_x', APP.DEFAULT.imgmask.offset.x, @on_imgmask_offset_change)
      imgmask_offset_y: new NumberUIOption('imgmask_offset_y', APP.DEFAULT.imgmask.offset.y, @on_imgmask_offset_change)
      move_perc:   new NumberUIOption('all_points_move_perc_option',  @move_perc * 100, @on_move_perc_option_change)
      draw_style:  new EnumUIOption('draw_style',           APP.DEFAULT.cursor.draw_style,  @set_draw_style)
      data_source: new EnumUIOption('movement_data_source', APP.DEFAULT.cursor.data_source, @set_data_source)

    @imgmask_overlay_state = {}
    changefunc = @on_imgmask_overlay_change

    for varname in ['imgmask_scale_width', 'imgmask_scale_height', 'imgmask_offset_x', 'imgmask_offset_y']
      @imgmask_overlay_state[varname] = false
      @option[varname].interaction_callbacks(varname, changefunc, changefunc)

    @update_imgmask_scale()
    @update_imgmask_offset()
    @on_imgmask_enabled_change()
    @imgmask_file.addEventListener('change', @on_imgmask_file_change)
    @imgmask_file_button.addEventListener('click', @on_imgmask_file_button_click, false)

    @imgmask_url.addEventListener('input', @on_imgmask_url_change)
    @imgmask_url.addEventListener('keyup', @on_imgmask_url_keyup)
    @imgmask_url_button.addEventListener('click', @on_imgmask_url_button_click, false)

    @btn_set_all_points.addEventListener('click', @on_set_all_points)

  save_imgmask: (include_large_data = true) ->
    opt =
      enabled: @option.imgmask_enabled.get()
      threshold:  @option.imgmask_threshold.get()
      oversample: @option.imgmask_oversample.get()
      scale:
        width:  @option.imgmask_scale_width.get()
        height: @option.imgmask_scale_height.get()
      offset:
        x: @option.imgmask_offset_x.get()
        y: @option.imgmask_offset_y.get()

    if opt.enabled
      if @imgmask_img_url?
        if @imgmask_img_url.length > MAX_LARGE_DATA_SIZE and not include_large_data
          opt.enabled = false
        else
          opt.mask_image_url = @imgmask_img_url
      else
        opt.enabled = false

    opt

  load_imgmask: (opt) ->
    if opt.threshold?
      @option.imgmask_threshold.set(opt.threshold)

    if opt.oversample?
      @option.imgmask_oversample.set(opt.oversample)

    if opt.scale?
      if opt.scale.width? and opt.scale.height?
        @option.imgmask_scale_width.set(opt.scale.width)
        @option.imgmask_scale_height.set(opt.scale.height)

    if opt.offset?
      if opt.offset.x? and opt.offset.y?
        @option.imgmask_offset_x.set(opt.offset.x)
        @option.imgmask_offset_y.set(opt.offset.y)

    if opt.enabled?
      if opt.enabled
        if opt.mask_image_url?
          @set_imgmask_enabled(true)
          @imgmask_load_image_url(opt.mask_image_url)
        else
          @set_imgmask_enabled(false)
      else
        @set_imgmask_enabled(false)

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
    @set_single_step_func()
    APP.resumable_reset()

  set_single_step_func: ->
    return @single = @single_step_destinaion unless @option?.data_source?

    @single_step = if @option?.imgmask_enabled.value and @imgmask_img_ready
      switch @option.data_source.get()
        when 'dest' then @single_step_destination_imgmask
        when 'orig' then @single_step_origin_imgmask
        else
          @single_step_destination_imgmask

    else
      switch @option.data_source.get()
        when 'dest' then @single_step_destination
        when 'orig' then @single_step_origin
        else
          @single_step_destination

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

  set_imgmask_enabled: (value) ->
    @option.imgmask_enabled.set(value)
    @on_imgmask_enabled_change()

  on_imgmask_enabled_change: =>
    if @option?.imgmask_enabled?
      @set_single_step_func()
      val = @option.imgmask_enabled.value
      APP.imgmask_enabled = val
      if val
        @enable_imgmask()
      else
        @disable_imgmask()

  on_imgmask_threshold_change: =>
    if @imgmask_img_ready
      @imgmask_convert_img_to_bitmap()
      if @option.imgmask_enabled.value
        APP.resumable_reset()

  on_imgmask_oversample_change: =>
    if @imgmask_img_ready
      @imgmask_prepare_bitmap()
      if @option.imgmask_enabled.value
        APP.resumable_reset()

  update_imgmask_scale: ->
    @imgmask_scaleperc_width  = @option.imgmask_scale_width.value  / 100
    @imgmask_scaleperc_height = @option.imgmask_scale_height.value / 100

  update_imgmask_offset: ->
    @imgmask_offset_x = @option.imgmask_offset_x.get()
    @imgmask_offset_y = @option.imgmask_offset_y.get()

  on_imgmask_scale_change: =>
    @update_imgmask_scale()
    @update_imgmask_bitmap()

  on_imgmask_offset_change: =>
    @update_imgmask_offset()
    @update_imgmask_bitmap()

  real_update_imgmask_bitmap: ->
    @imgmask_convert_img_to_bitmap()

    if @option.imgmask_enabled.value
      APP.resumable_reset()
    else
      APP.redraw_ui() if APP.show_imgmask_overlay

  run_pending_imgmask_bitmap_update: ->
    if @have_deferred_imgmask_bitmap_update
      @have_deferred_imgmask_bitmap_update = false
      console.log('running previously deferred bitmap conversion')
      @real_update_imgmask_bitmap()

  update_imgmask_bitmap: ->
    if @imgmask_img_ready
      if @imgmask_defer_convert_img_to_bitmap
        console.log('deferring bitmap conversion')
        @have_deferred_imgmask_bitmap_update = true
      else
        @real_update_imgmask_bitmap()

    else
      APP.redraw_ui() if APP.show_imgmask_overlay

  any_imgmask_overlay_state_focused: ->
    Object.values(@imgmask_overlay_state).flatten().reduce( (x, t) -> x or t )

  on_imgmask_overlay_change: (name, has_focus) =>
    @imgmask_overlay_state[name] = has_focus
    APP.show_imgmask_overlay = @any_imgmask_overlay_state_focused()
    APP.prepare_imgmask_overlay()
    APP.redraw_ui()

  imgmask_prepare_bitmap: ->
    @update_imgmask_scale()
    @update_imgmask_offset()

    if @imgmask_bitmap?
      @imgmask_image_data = null
      @imgmask_bitmap.remove()

    @imgmask_bitmap = document.createElement('canvas')

    @imgmask_oversample = @option.imgmask_oversample.value
    @imgmask_bitmap.width  = @imgmask_img_width  * @imgmask_oversample
    @imgmask_bitmap.height = @imgmask_img_height * @imgmask_oversample

    [canvas_width, canvas_height] = APP.max_xy()
    @canvas_width_to_bitmap_width   = @imgmask_bitmap.width / canvas_width
    @canvas_height_to_bitmap_height = @imgmask_bitmap.height / canvas_height

    @imgmask_img_size_width.textContent     = '' + @imgmask_img_width
    @imgmask_img_size_height.textContent    = '' + @imgmask_img_height
    @imgmask_bitmap_size_width.textContent  = '' + @imgmask_bitmap.width
    @imgmask_bitmap_size_height.textContent = '' + @imgmask_bitmap.height

    @imgmask_bitmap_caption.parentElement.insertBefore(@imgmask_bitmap, @imgmask_bitmap_caption)
    @imgmask_bitmap_ctx = @imgmask_bitmap.getContext('2d', alpha: false)

    @imgmask_convert_img_to_bitmap()

  imgmask_convert_img_to_bitmap: ->
    w = @imgmask_bitmap.width
    h = @imgmask_bitmap.height
    hw = w / 2
    hh = h / 2

    @imgmask_dstimg_half_width  = Math.floor(hw * @imgmask_scaleperc_width)
    @imgmask_dstimg_half_height = Math.floor(hh * @imgmask_scaleperc_height)
    @imgmask_dstimg_width  = 2 * @imgmask_dstimg_half_width
    @imgmask_dstimg_height = 2 * @imgmask_dstimg_half_height

    @imgmask_dstimg_edge_x = hw - @imgmask_dstimg_half_width
    @imgmask_dstimg_edge_y = hh - @imgmask_dstimg_half_height
    @imgmask_dstimg_redge_x = @imgmask_dstimg_edge_x + @imgmask_dstimg_width
    @imgmask_dstimg_redge_y = @imgmask_dstimg_edge_y + @imgmask_dstimg_height

    @imgmask_bitmap_ctx.fillStyle = 'rgb(255,255,255)'
    @imgmask_bitmap_ctx.fillRect(0, 0, w, h)

    @imgmask_bitmap_ctx.drawImage(@imgmask_img,
      0, 0, @imgmask_img_width, @imgmask_img_height,
      @imgmask_dstimg_edge_x, @imgmask_dstimg_edge_y, @imgmask_dstimg_width, @imgmask_dstimg_height)

    @imgmask_image_data = @imgmask_bitmap_ctx.getImageData(0, 0, @imgmask_bitmap.width, @imgmask_bitmap.height)
    d = @imgmask_image_data.data
    threshold = @option.imgmask_threshold.value / 255.0

    for i in [0...(d.length)] by 4
      y = Color.srgb_to_luminance(d[i], d[i + 1], d[i + 2])
      x = if y < threshold then 0 else 255
      d[i    ] = x
      d[i + 1] = x
      d[i + 2] = x

    @imgmask_bitmap_ctx.putImageData(@imgmask_image_data, 0, 0)

  set_imgmask_img_ready: (newvalue) ->
    @imgmask_img_ready = newvalue
    @set_single_step_func()
    if @imgmask_img_ready
      for el in @imgmask_img_hide_list
        el.classList.remove('hidden')
    else
      for el in @imgmask_img_hide_list
        el.classList.add('hidden')

  on_imgmask_img_load: =>
    @imgmask_img_width  = @imgmask_img.naturalWidth  ? @imgmask_img.width
    @imgmask_img_height = @imgmask_img.naturalHeight ? @imgmask_img.height
    @imgmask_prepare_bitmap()
    @set_imgmask_img_ready(true)

  imgmask_load_image_url: (url) ->
    return unless url?
    uobj = @is_valid_imgmask_url(url)
    return unless url?

    @imgmask_img_url = url

    if uobj.protocol isnt 'data:' and url.length < MAX_LARGE_DATA_SIZE
      @imgmask_url.value = url
      @on_imgmask_url_change()

    @imgmask_img.remove() if @imgmask_img?
    @imgmask_img = new Image()
    @imgmask_img_caption.parentElement.insertBefore(@imgmask_img, @imgmask_img_caption)
    @imgmask_img.onload = @on_imgmask_img_load
    @imgmask_img.src = @imgmask_img_url

  on_imgmask_file_reader_load: (event) =>
    @imgmask_load_image_url(event.target.result)

  on_imgmask_file_change: =>
    return if @imgmask_file.files.length < 1
    file = @imgmask_file.files[0]
    return unless file.type.startsWith('image/')

    @set_imgmask_img_ready(false)
    reader = new FileReader()
    reader.onload = @on_imgmask_file_reader_load

    reader.readAsDataURL(file)

  on_imgmask_file_button_click: =>
    @imgmask_file.click() if @imgmask_file?

  on_imgmask_url_change: =>
    @imgmask_url_button.disabled = true

    str = @imgmask_url.value
    if str?.length > 0
      if @is_valid_imgmask_url(str)
        @imgmask_url_button.disabled = false

  on_imgmask_url_button_click: =>
    @imgmask_load_image_url(@imgmask_url.value)

  is_valid_imgmask_url: (str) ->
    try
      new URL(str, window.location)
    catch e
      if e instanceof TypeError
        return false
      else
        throw e

  on_imgmask_url_keyup: (event) =>
    if (event.key) is "Enter"
      @on_imgmask_url_button_click()

  enable_imgmask: ->
    @option.imgmask_scale_width.enable()
    @option.imgmask_scale_height.enable()
    @option.imgmask_offset_x.enable()
    @option.imgmask_offset_y.enable()
    @option.imgmask_threshold.enable()
    @option.imgmask_oversample.enable()
    @imgmask_file.disabled = false
    @imgmask_file_button.disabled = false
    @imgmask_url.disabled = false
    @on_imgmask_url_change()

  disable_imgmask: ->
    @option.imgmask_scale_width.disable()
    @option.imgmask_scale_height.disable()
    @option.imgmask_offset_x.disable()
    @option.imgmask_offset_y.disable()
    @option.imgmask_threshold.disable()
    @option.imgmask_oversample.disable()
    @imgmask_file.disabled = true
    @imgmask_file_button.disabled = true
    @imgmask_url.disabled = true
    @imgmask_url_button.disabled = true

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
    @restrictions.set_visible(APP.points.length)
    @restricted.single_origin = @filtered_choices('single')
    @restricted.double_origin = @filtered_choices('double')
    @prev_target[0] = @prev_target[1] = APP.points[0]

  random_point: ->
    choices = @current_restricted_choices()
    choice = choices[ parseInt(Math.random() * choices.length) ]
    prev_idx = APP.points.indexOf(@prev_target[0])
    idx = (choice + prev_idx) % APP.points.length

    APP.points[idx]

  draw_graph: (target) ->
    @prev_target[2] = @prev_target[1]
    @prev_target[1] = @prev_target[0]
    @prev_target[0] = target

    ctx = APP.graph_ctx
    ctx.fillStyle = @get_current_color(target)
    ctx.fillRect(@x, @y, 1, 1)
    return null

  single_step_origin: ->
    target = @random_point()
    return false unless target?
    origin = @prev_target[0]

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

  single_step_origin_imgmask: ->
    origin = @prev_target[0]
    tries = []

    for choice in @current_restricted_choices().shuffle()
      prev_idx = APP.points.indexOf(origin)
      idx = (choice + prev_idx) % APP.points.length
      target = APP.points[idx]

      coords = if origin.move_perc_mode
        @coords_after_move_perc_towards_target(target, origin.move_perc)
      else
        @coords_after_move_absolute_towards_target(target, origin.move_perc)

      if @collides_with_bitmap(coords...)
        tries.push( target: target, coords: coords )
        continue

      @move_no_text_update_array(coords)

      @draw_graph(target)
      return true

    @log_all_targets_collide(tries)
    return false

  single_step_destination_imgmask: ->
    tries = []
    for choice in @current_restricted_choices().shuffle()
      prev_idx = APP.points.indexOf(@prev_target[0])
      idx = (choice + prev_idx) % APP.points.length
      target = APP.points[idx]

      coords = if target.move_perc_mode
        @coords_after_move_perc_towards_target(target, target.move_perc)
      else
        @coords_after_move_absolute_towards_target(target, target.move_perc)

      if @collides_with_bitmap(coords...)
        tries.push( target: target, coords: coords )
        continue

      @move_no_text_update_array(coords)

      @draw_graph(target)
      return true

    @log_all_targets_collide(tries)
    return false

  log_all_targets_collide: (tries) ->
    APP.redraw_ui()
    console.log('All moves collide with the bitmap')
    console.log('Current location xy', @x, @y)

    for t, idx in tries
      target G= t.target
      coords = t.coords
      console.log(" * Try ##{idx}: target '#{target.name}' at xy", target.x, target.y, 'coords xy', coords[0], coords[1])

  collides_with_bitmap: (x, y) ->
    #return false unless @imgmask_scale_width  < x < @imgmask_img_redge_x
    #return false unless @imgmask_scale_height < y < @imgmask_img_redge_y

    x -= @imgmask_offset_x
    y -= @imgmask_offset_y

    testx = Math.floor(x * @canvas_width_to_bitmap_width)
    testy = Math.floor(y * @canvas_height_to_bitmap_height)

    offset = ((testy * @imgmask_bitmap.width) + testx) * 4
    return (@imgmask_image_data.data[offset]) < 128

    #pixel = @imgmask_bitmap_ctx.getImageData(testx, testy, 1, 1)
    #return (pixel.data[0]) < 128

class DNDHandler
  constructor: (@optname, @defer_bitmap_updates = true) ->
    @option = APP.cur.option[@optname]
    @oldvalue = @option.get()
    @newvalue = @oldvalue

    if @defer_bitmap_updates
      APP.cur.imgmask_defer_convert_img_to_bitmap = true

  move: (x, y) ->
    @newvalue = @loc_to_value(x, y)
    @option.set(@newvalue)

  commit: ->
    if @defer_bitmap_updates
      APP.cur.imgmask_defer_convert_img_to_bitmap = false
      APP.cur.run_pending_imgmask_bitmap_update()

    if @newvalue isnt @oldvalue
      @on_change() if @on_change?

class OffsetDNDHandler extends DNDHandler
  on_change: ->
    APP?.cur.on_imgmask_offset_change()

class XOffsetDNDHandler extends OffsetDNDHandler
  loc_to_value: (x, y) ->
    newvalue = x - APP.image_edge_x
    newvalue

class YOffsetDNDHandler extends OffsetDNDHandler
  loc_to_value: (x, y) ->
    newvalue = y - APP.image_edge_y
    newvalue

class ScaleDNDHandler extends DNDHandler
  on_change: ->
    APP?.cur.on_imgmask_scale_change()

class ScaleWidthDNDHandler extends ScaleDNDHandler
  loc_to_value: (x, y) ->

class ScaleHeightDNDHandler extends ScaleDNDHandler
  loc_to_value: (x, y) ->

class MultiDNDHandler
  constructor: (handlers...) ->
    @handlers = handlers

  move: (x, y) ->
    APP.cur.imgmask_defer_convert_img_to_bitmap = true
    for h in @handlers
      h.move(x, y)

  commit: ->
    APP.cur.imgmask_defer_convert_img_to_bitmap = false
    APP.cur.run_pending_imgmask_bitmap_update()

    for h in @handlers
      h.commit()

class TargetRestrictionOption
  constructor: (@context, @offset, @name) ->
    selector = "#restrict_table .#{@name}"
    @column_cells    = @context.querySelectorAll(selector)

    single_selector = "#{selector}.single input[type=\"checkbox\"]"
    double_selector = "#{selector}.double input[type=\"checkbox\"]"
    @checkbox_single = @context.querySelector(single_selector)
    @checkbox_double = @context.querySelector(double_selector)

    @replace_with_styled_label(@checkbox_single)
    @replace_with_styled_label(@checkbox_double)

    @callbacks_single = []
    @callbacks_double = []

    @visible = false

    @reset()

    @checkbox_single.addEventListener 'change', @on_change_single
    @checkbox_double.addEventListener 'change', @on_change_double

  replace_with_styled_label: (checkbox) ->
    cell = checkbox.parentElement
    container     = @context.createElement('label')
    mark_inactive = @context.createElement('span')
    mark_active   = @context.createElement('span')

    mark_active.textContent = '\u2613'

    container.setAttribute('for', checkbox.id)
    container.classList.add('styled_checkbox_container')
    checkbox.classList.add('hidden_checkbox')
    mark_inactive.classList.add('checkmark')
    mark_inactive.classList.add('inactive')
    mark_active.classList.add('checkmark')
    mark_active.classList.add('active')

    container.appendChild(checkbox)
    container.appendChild(mark_inactive)
    container.appendChild(mark_active)
    cell.appendChild(container)

  add_callback_on_changes_single: (callback) ->
    @callbacks_single.push(callback)

  add_callback_on_changes_double: (callback) ->
    @callbacks_double.push(callback)

  reset: ->
    @set_single(false)
    @set_double(false)

  set_column_cells: (state) ->
    for cell in @column_cells
      cell.style.display = state

  show: ->
    @visible = true
    @set_column_cells('table-cell')

  hide: ->
    @visible = false
    @set_column_cells('none')

  enable_single: ->
    @checkbox_single.disabled = false

  enable_double: ->
    @checkbox_double.disabled = false

  disable_single: ->
    @checkbox_single.disabled = true

  disable_double: ->
    @checkbox_double.disabled = true

  is_single_enabled: ->
    not @checkbox_double.disabled

  is_double_enabled: ->
    not @checkbox_double.disabled

  using_double: ->
    @visible and @is_double_enabled() and @value_double

  set_single: (value) ->
    if value isnt @value_single
      @value_single = value
      @checkbox_single.checked = @value_single
      cb(value) for cb in @callbacks_single
      APP.update_metadata_and_reset()

  set_double: (value) ->
    if value isnt @value_double
      @value_double = value
      @checkbox_double.checked = @value_double
      cb(value) for cb in @callbacks_double
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
        new TargetRestrictionOption(@context, -4, 'prev4')
      ]
      self: new TargetRestrictionOption(@context,  0, 'self')
      next: [
        new TargetRestrictionOption(@context,  1, 'next1'),
        new TargetRestrictionOption(@context,  2, 'next2'),
        new TargetRestrictionOption(@context,  3, 'next3'),
        new TargetRestrictionOption(@context,  4, 'next4')
      ]
      opposite: new TargetRestrictionOption(@context,  5, 'opposite'),

    @options = Object.values(@option).flatten()

    @by_name = {}
    for o in @options
      @by_name[o.name] = o

    @option.self.add_callback_on_changes_single(@on_self_singe_change)

  on_self_singe_change: (is_restricted) =>
    if is_restricted
      @disable_double()
    else
      @enable_double()

  enable_double: ->
    for o in @options
      o.enable_double()

  disable_double: ->
    for o in @options
      o.disable_double()

  find: (name) ->
    if @by_name[name]?
      @by_name[name]
    else
      console.log("no such restriction named '#{name}'")
      null

  set_visible: (n) ->
    o.hide() for o in @options

    @option.self.show()
    n -= 1

    if n % 2 == 1
      @option.opposite.show()
      n -= 1

    neighbor = 1
    while n >= 2
      [prev, next] = @neighbor(neighbor)
      prev.show()
      next.show()

      n -= 2
      neighbor += 1

    null

  using_double: ->
    for o in @options
      return true if o.using_double()
    return false

  restricted_single: ->
    @options.filter( (o) -> o.value_single )

  restricted_double: ->
    @options.filter( (o) -> o.value_double )

  neighbor: (n) ->
    [@by_name["prev#{n}"], @by_name["next#{n}"]]

  save: (include_large_data = true) ->
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

  load_default_state: ->
    o.reset() for o in @options

class UIOption
  constructor: (@id, @default, @on_change_callback = null) ->
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

  enable: ->
    @el.disabled = false

  disable: ->
    @el.disabled = true

  interaction_callbacks: (@interaction_name, @focus_callback, @blur_callback) ->
    unless @interaction_events_captured?
      @el.addEventListener('focus',      @on_focus)
      @el.addEventListener('blur',       @on_blur)
      @el.addEventListener('mouseenter', @on_mouseenter)
      @el.addEventListener('mouseleave', @on_mouseleave)
      @interaction_events_captured = true
      @have_focus = false
      @have_mouse = false

  on_focus: =>
    @have_focus = true
    if @focus_callback?
      @focus_callback(@interaction_name, true) unless @have_mouse

  on_blur: =>
    @have_focus = false
    if @blur_callback?
      @blur_callback(@interaction_name, false) unless @have_mouse

  on_mouseenter: =>
    @have_mouse = true
    if @focus_callback?
      @focus_callback(@interaction_name, true) unless @have_focus

  on_mouseleave: =>
    @have_mouse = false
    if @blur_callback?
      @blur_callback(@interaction_name, false) unless @have_focus

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
    @value = switch bool_value
      when 'true'  then true
      when 'false' then false
      else
        !!bool_value
    @el.checked = @value

class NumberUIOption extends UIOption
  @create: (parent, @id, rest...) ->
    opt = new NumberUIOption(APP.create_input_element('number', @id), rest...)
    parent.appendChild(opt.el)
    opt

  get: (element = @el) ->
    parseInt(element.value)

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
  MAX_POINTS: 10
  REG_POLYGON_MARGIN: 10
  NEARBY_RADIUS: 8

  DEFAULT:
    show_tooltips: true
    graph:
      width:  420
      height: 420
    lock_aspect: true
    draw_opacity:   35
    move_range_min: 0
    move_range_max: 100
    move_perc: 0.5
    cursor:
      draw_style: 'color_blend_prev_color'
      data_source: 'dest'
    imgmask:
      enabled: false
      scale:
        width:  50
        height: 50
      offset:
        x: 0
        y: 0
      threshold: 1
      oversample: 1

  points: []
  move_absolute_magnitude: 100

  constructor: (@context) ->

  init: () ->
    @running = false

    @enable_imgmask_dnd = false

    @mouse_over_graph = false
    @show_imgmask_overlay = false
    @imgmask_enabled = false
    @imgmask_overlay_highlight = null

    @step_count = 0

    @steps_per_frame_el = @context.getElementById('steps_per_frame')
    @content_el       = @context.getElementById('content')

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
      show_tooltips:    new BoolUIOption(  'show_tooltips',    APP.DEFAULT.show_tooltips,    @on_show_tooltips_change)
      canvas_width:     new NumberUIOption('canvas_width',     APP.DEFAULT.graph.width,      @on_canvas_width_change)
      canvas_height:    new NumberUIOption('canvas_height',    APP.DEFAULT.graph.height,     @on_canvas_height_change)
      lock_aspect:      new BoolUIOption(  'lock_aspect',      APP.DEFAULT.lock_aspect)
      draw_opacity:     new NumberUIOption('draw_opacity',     APP.DEFAULT.draw_opacity,     @on_draw_opacity_change)
      move_range_min:   new NumberUIOption('move_range_min',   APP.DEFAULT.move_range_min,   @on_move_range_change)
      move_range_max:   new NumberUIOption('move_range_max',   APP.DEFAULT.move_range_max,   @on_move_range_change)

    @serializebox        = @context.getElementById('serializebox')
    @serializebox_title  = @context.getElementById('serializebox_title')
    @serializebox_text   = @context.getElementById('serializebox_text')
    @serializebox_action = @context.getElementById('serializebox_action')
    @serializebox_cancel = @context.getElementById('serializebox_cancel')

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

    @resize_graph(@option.canvas_width.get(), @option.canvas_height.get())

    @cur = new DrawPoint('Cur')

    @load_default_state()

    @set_steps_per_frame(100, false)

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

    window.addEventListener 'hashchange', @on_hashchange

    @clear_update_and_draw()

  debug: (msg) ->
    unless @debugbox?
      @debugbox = @context.getElementById('debugbox')
      @debugbox_hdr = @debugbox.querySelector('.hdr')
      @debugbox_msg = @debugbox.querySelector('.msg')
      @debugbox.classList.remove('hidden')

    timestamp = new Date()
    @debugbox_hdr.textContent = timestamp.toISOString()
    @debugbox_msg.textContent = '' + msg

  load_default_state: ->
    @set_ngon(3)

    @option.canvas_width.set(APP.DEFAULT.graph.width)
    @option.canvas_height.set(APP.DEFAULT.graph.height)
    @option.draw_opacity.set(APP.DEFAULT.draw_opacity)
    @option.move_range_min.set(APP.DEFAULT.move_range_min)
    @option.move_range_max.set(APP.DEFAULT.move_range_max)
    @set_move_range()
    @cur.set_move_perc(APP.DEFAULT.move_perc * 100)
    @cur.set_draw_style(APP.DEFAULT.cursor.draw_style)
    @cur.set_data_source(APP.DEFAULT.cursor.data_source)

    p.load_default_state() for p in @points
    r.load_default_state() for r in @cur.restrictions

  create_element: (name, id = null) ->
    el = @context.createElement(name)
    el.id = id if id?
    el

  create_input_element: (type, id = null) ->
    el = @create_element('input', id)
    el.type = type
    el

  on_show_tooltips_change: (value) =>
    if value
      @content_el.classList.add('show_tt')
    else
      @content_el.classList.remove('show_tt')

    @serialize_cookie('show_tooltips', value)

  on_move_range_change: =>
    @set_move_range(@option.move_range_min.get(), @option.move_range_max.get())
    @resumable_reset()

  set_move_range: (min = APP.DEFAULT.move_range_min, max = APP.DEFAULT.move_range_max) ->
    @cur.set_move_range(min, max)
    for p in @points
      p.set_move_range(min, max)

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
    @mouse_over_graph = true
    @redraw_ui()

  on_mouseleave: =>
    @graph_wrapper.classList.remove('resizable')
    @mouse_over_graph = false
    @redraw_ui()

  on_graph_wrapper_mutate: (event) =>
    if @graph_wrapper.offsetWidth != @graph_ui_canvas.width or @graph_wrapper.offsetHeight != @graph_ui_canvas.height
      @aspect_safe_resize_graph(@graph_wrapper.offsetWidth, @graph_wrapper.offsetHeight)
      APP.resumable_reset()

  clamp_points_to_canvas: ->
    [width, height] = APP.max_xy()

    for p in APP.points
      p.x = 0 if p.x < 0
      p.y = 0 if p.y < 0
      p.x = width  - 1 if p.x >= width
      p.y = height - 1 if p.y >= height

  save_aspect_ratio: ->
    @aspect_ratio = @graph_canvas.width / @graph_canvas.height

  aspect_safe_resize_graph_width: (w) ->
    if @option.lock_aspect.value
      h = w / @aspect_ratio
      @resize_graph(w, h)
    else
      @resize_graph_width(w)

  aspect_safe_resize_graph_height: (h) ->
    if @option.lock_aspect.value
      w = h * @aspect_ratio
      @resize_graph(w, h)
    else
      @resize_graph_height(h)

  aspect_safe_resize_graph: (w, h) ->
    if @option.lock_aspect.value
      @aspect_safe_resize_graph_width(w)
    else
      @resize_graph(w, h)

  resize_graph_width: (w) ->
    w = parseInt(w)

    scale = w / @graph_canvas.width
    p.scale_width(scale) for p in @points

    style_width = "#{w}px"
    @graph_canvas.width = w
    @graph_ui_canvas.width = w
    @graph_wrapper.style.width = style_width
    @canvas_size_rule.style.width = style_width
    @option.canvas_width.set(w)

    @save_aspect_ratio()
    APP.prepare_imgmask_overlay()

  resize_graph_height: (h) ->
    h = parseInt(h)

    scale = h / @graph_canvas.height
    p.scale_height(scale) for p in @points

    style_height = "#{h}px"

    @graph_canvas.height = h
    @graph_ui_canvas.height = h
    @graph_wrapper.style.height = style_height
    @canvas_size_rule.style.height = style_height
    @option.canvas_height.set(h)

    @save_aspect_ratio()
    APP.prepare_imgmask_overlay()

  resize_graph: (w, h) ->
    @resize_graph_width(w)
    @resize_graph_height(h)

  on_canvas_width_change: =>
    @aspect_safe_resize_graph_width(@option.canvas_width.value) 
    @resumable_reset()

  on_canvas_height_change: =>
    @aspect_safe_resize_graph_height(@option.canvas_height.value)
    @resumable_reset()

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

  set_steps_per_frame: (int_value, save_to_cookie = true) ->
    @old_steps_per_frame = @steps_per_frame
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

    if save_to_cookie
      unless @old_steps_per_frame == @steps_per_frame
        @serialize_cookie('steps_per_frame', @steps_per_frame)

  on_create_png: =>
    @open_in_new_window(@graph_canvas.toDataURL('png'))

  open_in_new_window: (url) ->
    window.open(url, '_blank')

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

  serialize: (include_large_data = true) ->
    opt =
      points: @points.map( (x) -> x.save() )
      restrictions: @cur.restrictions.save(include_large_data)
      options:
        canvas_width:  @option.canvas_width.value
        canvas_height: @option.canvas_height.value
        lock_aspect:   @option.lock_aspect.value
        draw_opacity:  @option.draw_opacity.value
        draw_style:    @cur.option.draw_style.get()
        data_source:   @cur.option.data_source.get()
        all_points_move_perc: @cur.option.move_perc.get()
        move_absolute_magnitude: @move_absolute_magnitude
        move_range_min: @option.move_range_min.get()
        move_range_max: @option.move_range_max.get()
        imgmask: @cur.save_imgmask(include_large_data)

    JSON.stringify(opt)

  deserialize: (text) =>
    opt = JSON.parse(text)

    if opt.options?
      if opt.options.canvas_width? and opt.options.canvas_width?
        @resize_graph(opt.options.canvas_width, opt.options.canvas_width)

      if opt.options.lock_aspect?
        @option.lock_aspect.set(opt.options.lock_aspect)

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

      if opt.options.imgmask
        @cur.load_imgmask(opt.options.imgmask)

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
    hash = @serialize(false)
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

  get_overlay_highlight_dnd_handler: (side) ->
    switch side
      when 'left'   then new XOffsetDNDHandler('imgmask_offset_x')
      when 'top'    then new YOffsetDNDHandler('imgmask_offset_y')
      when 'right'  then new ScaleWidthDNDHandler( 'imgmask_scale_width')
      when 'bottom' then new ScaleHeightDNDHandler('imgmask_scale_height')

      when 'TL'
        new MultiDNDHandler(
          new XOffsetDNDHandler('imgmask_offset_x', false),
          new YOffsetDNDHandler('imgmask_offset_y', false))

      when 'BR'
        new MultiDNDHandler(
          new ScaleWidthDNDHandler( 'imgmask_scale_width',  false),
          new ScaleHeightDNDHandler('imgmask_scale_height', false))

      else
        null

  on_mousedown: (event) =>
    if @dnd_target?
      @dnd_target.commit() if @dnd_target.commit?
      @dnd_target = null

    @unhighlight_all()
    loc = @event_to_canvas_loc(event)
    p = @first_nearby_point(loc)
    if p?
      @dnd_target = p
      p.highlight()
      #console.log('mousedown point', p)
    else
      if @enable_imgmask_dnd
        @find_nearby_imgmask_highlight(loc.x, loc.y, false)
        if @imgmask_overlay_highlight?
          @dnd_target = @get_overlay_highlight_dnd_handler(@imgmask_overlay_highlight)
          #console.log('mousedown overlay', loc, @dnd_target)
        else
          #console.log('mousedown (nothing)')

  on_mouseup: (event) =>
    if @dnd_target?
      loc = @event_to_canvas_loc(event)
      #console.log('mouseup', @dnd_target, 'loc', loc)
      if @is_inside_ui(loc)
        @dnd_target.move(loc.x, loc.y)
        @dnd_target.commit() if @dnd_target.commit?
        #console.log('@dnd_target movement committed, redrawing ui')
        @redraw_ui()
        @resumable_reset()
      else
        #console.log('loc is not inside ui!')

      @dnd_target = null
    else
      #console.log('mouseup with null @dnd_target!')

  on_mousemove: (event) =>
    # lasttime = (@last_mousemove ? 0)
    # @last_mousemove = Date.now()
    # dt = @last_mousemove - lasttime
    # return if dt < 500
    # @debug(dt)

    loc = @event_to_canvas_loc(event)
    if @dnd_target?
      #console.log("mousemove(#{dt})", @dnd_target, 'loc', loc)
      if @is_inside_ui(loc)
        @dnd_target.move(loc.x, loc.y)
        #console.log('@dnd_target moved to loc', loc, '@redraw_ui(false)')
        @redraw_ui(false)
        #@resumable_reset()
      #else
        #console.log('loc is not inside ui! (NOT REDRAWING UI)')
    else
      #console.log("mousemove(#{dt})",'no pending @dnd_target', 'loc', loc)
      redraw = @unhighlight_all()

      p = @first_nearby_point(loc)
      if p?
        redraw = true if p.highlight()

      if @enable_imgmask_dnd
        if @find_nearby_imgmask_highlight(loc.x, loc.y, false)
          #console.log('changed highlight to', @imgmask_overlay_highlight)
          redraw = true

      if redraw
        #console.log('no pending @dnd_target; @redraw_ui()')
        @redraw_ui()
      else
        #console.log('no pending @dnd_target; (NOT REDRAWING UI)')

  find_nearby_imgmask_highlight: (mx, my, redraw_on_change = true) ->
    oldhighlight = @imgmask_overlay_highlight
    esize = 6
    bsize = 8

    if      (@image_edge_x - bsize) < mx < (@image_edge_x + bsize) and (@image_edge_y - bsize) < my < (@image_edge_y + bsize)
      @imgmask_overlay_highlight = 'TL'
    else if (@image_faredge_x - bsize) < mx < (@image_faredge_x + bsize) and (@image_faredge_y - bsize) < my < (@image_faredge_y + bsize)
      @imgmask_overlay_highlight = 'BR'

    else if @image_edge_x < mx < @image_faredge_x and (@image_edge_y - esize) < my < (@image_edge_y + esize)
      @imgmask_overlay_highlight = 'top'
    else if @image_edge_y < my < @image_faredge_y and (@image_edge_x - esize) < mx < (@image_edge_x + esize)
      @imgmask_overlay_highlight = 'left'
    else if @image_edge_x < mx < @image_faredge_x and (@image_faredge_y - esize) < my < (@image_faredge_y + esize)
      @imgmask_overlay_highlight = 'bottom'
    else if @image_edge_y < my < @image_faredge_y and (@image_faredge_x - esize) < mx < (@image_faredge_x + esize)
      @imgmask_overlay_highlight = 'right'

    else
      @imgmask_overlay_highlight = null

    if oldhighlight isnt @imgmask_overlay_highlight
      return true
    else
      return false

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
      return true
    else
      return false

  step: =>
    @single_step()

    @update_info_elements()
    @redraw_ui()
    return null

  multistep: ->
    for [0...@steps_per_frame]
      unless @single_step()
        @stop() if @running
        console.log('forced stop!')
        break

    @update_info_elements()
    @redraw_ui()
    return null

  prepare_imgmask_overlay: =>
    return unless @cur?
    cw = @graph_ui_canvas.width
    ch = @graph_ui_canvas.height
    hcw = cw / 2
    hch = ch / 2

    scaled_half_width  = Math.floor(hcw * (@cur.option.imgmask_scale_width.get()  / 100))

    scaled_half_height = Math.floor(hch * (@cur.option.imgmask_scale_height.get() / 100))

    @image_width  = 2 * scaled_half_width
    @image_height = 2 * scaled_half_height
    @image_edge_x = hcw - scaled_half_width
    @image_edge_y = hch - scaled_half_height

    #msg = "correcting @image_edge_xy(#{@image_edge_x}, #{@image_edge_y}) + imgmask_offset_xy(#{@cur.option.imgmask_offset_x.get()}, #{@cur.option.imgmask_offset_y.get()}) => (#{@image_edge_x + @cur.option.imgmask_offset_x.get()}, #{@image_edge_y + @cur.option.imgmask_offset_y.get()})"
    #@debug(msg)
    #console.log(msg)

    @image_edge_x += @cur.option.imgmask_offset_x.get()
    @image_edge_y += @cur.option.imgmask_offset_y.get()

    @image_faredge_x = @image_edge_x + @image_width
    @image_faredge_y = @image_edge_y + @image_height

  render_imgmask_overlay: (render_bitmap_preview = true) ->
    @prepare_imgmask_overlay()
    @render_overlay_bitmap_preview() if @cur.imgmask_img_ready and render_bitmap_preview?
    @render_overlay_margin_shading()
    @render_overlay_highlight() if @enable_imgmask_dnd and @imgmask_overlay_highlight?

  render_overlay_bitmap_preview: ->
    @graph_ui_ctx.save()
    oldalpha = @graph_ui_ctx.globalAlpha
    @graph_ui_ctx.globalAlpha = 0.5
    @graph_ui_ctx.drawImage(@cur.imgmask_bitmap,
      0, 0, @cur.imgmask_bitmap.width, @cur.imgmask_bitmap.height,
      @cur.imgmask_offset_x, @cur.imgmask_offset_y, @graph_ui_canvas.width, @graph_ui_canvas.height)
    @graph_ui_ctx.globalAlpha = oldalpha
    @graph_ui_ctx.restore()

  render_overlay_margin_shading: ->
    @graph_ui_ctx.save()
    img_region = new Path2D()
    img_region.rect(@image_edge_x, @image_edge_y, @image_width, @image_height)
    img_region.rect(0, 0, @graph_ui_canvas.width, @graph_ui_canvas.height)
    @graph_ui_ctx.clip(img_region, 'evenodd')
    @graph_ui_ctx.fillStyle = 'rgba(255, 65, 2, 0.2)'
    @graph_ui_ctx.fillRect(0, 0, @graph_ui_canvas.width, @graph_ui_canvas.height)
    @graph_ui_ctx.restore()

  render_overlay_highlight: ->
    linewidth = 3
    extralinewidth = 2
    biglinewidth = linewidth + extralinewidth
    linetrim = biglinewidth + 4
    cornerbox_size = 2 * linetrim

    dx = @image_faredge_x - @image_edge_x
    dy = @image_faredge_y - @image_edge_y
    min_delta = Math.min(dx, dy)
    linetrim = min_delta if linetrim > min_delta

    cb_offset = 8
    cb_margin = 3

    draw = null
    hl_top    = false
    hl_left   = false
    hl_bottom = false
    hl_right  = false

    switch @imgmask_overlay_highlight
      when 'TL'
        draw = 'TL'
        hl_top  = true
        hl_left = true
      when 'BR'
        draw = 'BR'
        hl_bottom = true
        hl_right  = true

      when 'top'
        draw = 'TL'
        hl_top = true
      when 'left'
        draw = 'TL'
        hl_left = true

      when 'bottom'
        draw = 'BR'
        hl_bottom = true
      when 'right'
        draw = 'BR'
        hl_right = true

      else
        console.log('bad @imgmask_overlay_highlight value', @imgmask_overlay_highlight)
        return

    @graph_ui_ctx.save()
    @graph_ui_ctx.beginPath()

    switch draw
      when 'TL'
        @graph_ui_ctx.moveTo(@image_faredge_x - linetrim, @image_edge_y)
        @graph_ui_ctx.lineTo(@image_edge_x, @image_edge_y)
        @graph_ui_ctx.lineTo(@image_edge_x, @image_faredge_y - linetrim)
      when 'BR'
        @graph_ui_ctx.moveTo(@image_edge_x + linetrim, @image_faredge_y)
        @graph_ui_ctx.lineTo(@image_faredge_x, @image_faredge_y)
        @graph_ui_ctx.lineTo(@image_faredge_x, @image_edge_y + linetrim)

    @graph_ui_ctx.lineCap  = 'round'
    @graph_ui_ctx.lineJoin = 'round'
    @graph_ui_ctx.strokeStyle = '#000'
    @graph_ui_ctx.lineWidth = linewidth + extralinewidth
    @graph_ui_ctx.stroke()

    @graph_ui_ctx.beginPath()
    @graph_ui_ctx.lineCap = 'none'
    @graph_ui_ctx.lineJoin = 'miter'
    @graph_ui_ctx.strokeStyle = '#FFFF00'
    @graph_ui_ctx.lineWidth = linewidth
    @graph_ui_ctx.setLineDash([3, 5])

    if hl_top
      @graph_ui_ctx.moveTo(@image_faredge_x - linetrim, @image_edge_y)
      @graph_ui_ctx.lineTo(@image_edge_x + linetrim, @image_edge_y)
      @graph_ui_ctx.stroke()

    if hl_left
      @graph_ui_ctx.moveTo(@image_edge_x, @image_faredge_y - linetrim)
      @graph_ui_ctx.lineTo(@image_edge_x, @image_edge_y + linetrim)
      @graph_ui_ctx.stroke()

    if hl_bottom
      @graph_ui_ctx.moveTo(@image_edge_x + linetrim, @image_faredge_y)
      @graph_ui_ctx.lineTo(@image_faredge_x - linetrim, @image_faredge_y)
      @graph_ui_ctx.stroke()

    if hl_right
      @graph_ui_ctx.moveTo(@image_faredge_x, @image_edge_y + linetrim)
      @graph_ui_ctx.lineTo(@image_faredge_x, @image_faredge_y - linetrim)
      @graph_ui_ctx.stroke()

    @render_overlay_cornerbox(draw, cornerbox_size, cb_offset, '#000')
    if @imgmask_overlay_highlight == 'TL' or @imgmask_overlay_highlight == 'BR'
      @render_overlay_cornerbox(draw, cornerbox_size - (2 * cb_margin), cb_offset - cb_margin, '#FFFF00')

    @graph_ui_ctx.restore()

  render_overlay_cornerbox: (draw, size, offset, style) ->
      @graph_ui_ctx.beginPath()

      switch draw
        when 'TL'
          x = @image_edge_x - offset
          y = @image_edge_y - offset
          @graph_ui_ctx.rect(x, y, size, size)
        when 'BR'
          x = @image_faredge_x + offset - size
          y = @image_faredge_y + offset - size
          @graph_ui_ctx.rect(x, y, size, size)

      @graph_ui_ctx.fillStyle = style
      @graph_ui_ctx.fill()

  redraw_ui: (render_bitmap_preview = true) =>
    @graph_ui_ctx.clearRect(0, 0, @graph_ui_canvas.width, @graph_ui_canvas.height)

    @cur?.draw_ui()

    for p in @points
      p.draw_ui()

    if @show_imgmask_overlay or (@enable_imgmask_dnd and @mouse_over_graph and @imgmask_enabled)
      @render_imgmask_overlay(render_bitmap_preview)

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
      #when "Enter"         then @on_run()
      when "Escape", "Esc" then @stop()
      #when "r", "R"        then @resumable_reset()
      #when "p", "P"        then @on_create_png()
      #when "s", "S"        then @on_save()
      #when "l", "L"        then @on_load()

  on_hashchange: =>
    if document.location.hash?.length > 1
      @deserialize(document.location.hash.slice(1))
    else
      @load_default_state()

  serialize_cookie: (key, value) ->
    document.cookie = "#{key}=#{value}"

  deserialize_cookie: (key, value) ->
    switch key
      when 'steps_per_frame' then @set_steps_per_frame(value)
      when 'show_tooltips'   then @option.show_tooltips.set(value)

  load_from_cookie: =>
    for cookie in document.cookie.split('; ')
      @deserialize_cookie(cookie.split('=')...)

document.addEventListener 'DOMContentLoaded', =>
  APP = new StochasticSierpinski(document)
  APP.init()
  APP.on_hashchange()
  APP.load_from_cookie()
