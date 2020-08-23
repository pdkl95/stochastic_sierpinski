<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Stochastic Sierpinski</title>
    <style type="text/css" media="screen">
undivert(`basic.css')
    </style>
    <style type="text/css" media="screen" title="app_stylesheet">
undivert(`style.css')
    </style>
  </head>
  <body>
    <header>
      <h1>Stochastic Sierpinski</h1>
    </header>

    <pre id="debugbox" class="hidden"><span class="hdr"></span><span class="msg"></span></pre>

    <div id="content" class="show_tt">
      <div class="graph panel">
        <div id="graph_wrapper" class="canvas_wrapper canvas_size">
          <canvas id="graph" class="graph_canvas canvas_size" width="420" height="420">
            This requires a browser that supports the &lt;canvas&gt; tag.
          </canvas>
          <canvas id="graph_ui" class="graph_canvas canvas_size" width="420" height="420">
            This requires a browser that supports the &lt;canvas&gt; tag.
          </canvas>
        </div>
      </div>

      <div class="info panel">
        <table id="all_points_table">
          <tr>
            <td colspan=3 class="right">
              <label for="move_range_min">MIN</label>
              <input id="move_range_min" name="move_range_min"
                     type="number" value="0" step="1">
              <label for="move_range_max" id="move_range_max_label">MAX</label>
              <input id="move_range_max" name="move_range_max"
                     type="number" value="100" step="1">
            </td>
          </tr>
          <tr>
            <td>
              <input type="number" id="all_points_move_perc_option" value=50>
            </td>
            <td>
              <input type="range" id="all_points_move_perc_range"
                     min="0" max="100" step="5" value="50">
            </td>
            <td class="move_mode" id="set_all_points_box">
              <button id="set_all_points">&darr;</button>
            </td>
          </tr>
        </table>
        <table id="misc_info_table">
          <tr>
            <th>Current X,Y</th>
            <td id="point_cur_x"></td>
            <td id="point_cur_y"></td>
          </tr>
          <tr>
            <th>Total Steps</th>
            <td id="total_steps" colspan=2></td>
          </tr>
        </table>
        <table id="point_pos_table">
          <tr>
            <th>P</th>
            <th>Color</th>
            <th>X</th>
            <th>Y</th>
            <th>Move %</th>
            <th colspan=2 class="right">Rel?</th>
          </tr>
        </table>
      </div>

      <div class="ui panel">
        <div class="runbox buttonbox">
          <button id="button_reset" class="tt ttright" data-title="Reset back to a blank canvas.">Reset</button>
          <button id="button_step" class="tt ttright" data-title="One step of the chaos game. Selects a random point, moves toward it, and draws a point.">Step 1x</button>
          <button id="button_multistep" class="tt ttright" data-title="Run a fixed number of steps. The number of steps can be changed with the 'Steps / Frame' option.">Step Nx</button>
          <button id="button_run" class="tt ttright" data-title="Draws 'Steps / Frame' points every frame until manually stopped by pressing Pause or Step">Run</button>
        </div>

        <div class="pointsbox buttonbox bbright">
          <span class="title">Points</span>
          <label for="num_points">
            N =
            <input type="number" id="num_points" value="3"
                   min="3" max="10" step="1">
          </label>
          <span class="title">Move All</span>
          <button id="move_all_reg_polygon" class="tt ttleft" data-title="Move all points into the corners of an N-sided regullar polygon.">Reg. Polygon</button>
          <button id="move_all_random" class="tt ttleft" data-title="Move all points to random positions.">Random</button>
        </div>

        <hr class="clear_both">

        <div class="imgbox buttonbox">
          <button id="button_create_png" class="tt ttright" data-title="Open the current canvas image as a PNG file in a new tab/window.">Create PNG</button>
          <button id="button_save_url" class="tt ttright" data-title="Saves the current settings to the hash (#) on the current URL. WARNING: Loaded images are NOT included! (URL length <= 2k)">Save as URL</button>
          <button id="button_save" class="tt ttright" data-title="Saves the current settings to copy-able JSON-formatted text.">Save as JSON</button>
          <button id="button_load" class="tt ttright" data-title="Paste the JSON-formatted text (from 'Save as JSON') to load previously saves settings.">Load from JSON</button>
        </div>

        <div class="uioptbox buttonbox bbright">
          <span class="title tt ttleft" data-title="User-Interface Options. These options do not affect the drawing results, so they are not saved with the other option. Instead, they are saved in a browser cookie.">UI Options</span>
          <label for="show_tooltips" class="tt ttleft" data-title="Enable/Disable tooltips similar tol what you are reading right now.">
            Show Tooltips
            <input id="show_tooltips" type="checkbox" checked="checked">
          </label>
          <label for="steps_per_frame" class="tt ttleft" data-title="The number of steps that are computed each frame. Higher values render fast at the cost of greater CPU load.">
            Steps / Frame
            <input type="number" id="steps_per_frame" min="0" max="500" step="10">
          </label>
        </div>

        <hr class="clear_both">

        <div class="optionsbox optionbox obright">
          <h3>Draw Options</h3>
          <table>
            <tr>
              <th>Canvas Size</th>
              <td>
                <input id="canvas_width" type="number" value="420"
                       min="64" max="4096" step="1">
                &nbsp;x&nbsp;
                <input id="canvas_height" type="number" value="420"
                       min="64" max="4096" step="1">
                <label for="lock_aspect" id="lock_aspect_label" class="tt ttleft" data-title="When enabled, all changes to the canvas size preserve the aspect ratio.">Lock Aspect</label>
                <input id="lock_aspect" type="checkbox" checked="checked">
              </td>
            </tr>
            <tr>
              <th>Draw Opacity</th>
              <td><input id="draw_opacity" type="number"
                         min="0" max="100" step="5">%</td>
            </tr>
            <tr>
              <th>Draw Style</th>
              <td>
                <select id="draw_style" name="draw_style">
                  <option value="mono">Monochrome (black on white)</option>
                  <option value="color_target">Target Point's Color</option>
                  <option value="color_blend_prev_target">blend(target, prev_target)</option>
                  <option value="color_blend_prev_color">blend(target, prev_blend)</option>
                </select>
              </td>
            </tr>
            <tr>
              <th>Data Source</th>
              <td>
                <select id="movement_data_source" name="movement_data_source">
                  <option value="dest">Destination</option>
                  <option value="orig">Origin</option>
                </select>
              </td>
            </tr>
          </table>
        </div>

        <div class="restrictbox optionbox obleft">
          <h3>Random Target Restrictions</h3>
          <table id="restrict_table">
            <tr>
              <td class="blank"></td>
              <th scope="col" class="header prev prev4">-4</th>
              <th scope="col" class="header prev prev3">-3</th>
              <th scope="col" class="header prev prev2">-2</th>
              <th scope="col" class="header prev prev1">-1</th>
              <th scope="col" class="header self">Self</th>
              <th scope="col" class="header next next1">+1</th>
              <th scope="col" class="header next next2">+2</th>
              <th scope="col" class="header next next3">+3</th>
              <th scope="col" class="header next next4">+4</th>
              <th scope="col" class="header opposite">Opp</th>
            </tr>
            <tr>
              <th scope="row">Last</th>
              <td class="single prev prev4"><input type="checkbox" id="restrict_single_prev_4"></td>
              <td class="single prev prev3"><input type="checkbox" id="restrict_single_prev_3"></td>
              <td class="single prev prev2"><input type="checkbox" id="restrict_single_prev_2"></td>
              <td class="single prev prev1"><input type="checkbox" id="restrict_single_prev_1"></td>
              <td class="single self">      <input type="checkbox" id="restrict_single_self"></td>
              <td class="single next next1"><input type="checkbox" id="restrict_single_next_1"></td>
              <td class="single next next2"><input type="checkbox" id="restrict_single_next_2"></td>
              <td class="single next next3"><input type="checkbox" id="restrict_single_next_3"></td>
              <td class="single next next4"><input type="checkbox" id="restrict_single_next_4"></td>
              <td class="single opposite">  <input type="checkbox" id="restrict_single_opposite"></td>
            </tr>
            <tr>
              <th scope="row" class="double">Last 2x</th> 
              <td class="double prev prev4"><input type="checkbox" id="restrict_double_prev_4"></td>
              <td class="double prev prev3"><input type="checkbox" id="restrict_double_prev_3"></td>
              <td class="double prev prev2"><input type="checkbox" id="restrict_double_prev_2"></td>
              <td class="double prev prev1"><input type="checkbox" id="restrict_double_prev_1"></td>
              <td class="double self">      <input type="checkbox" id="restrict_double_self"></td>
              <td class="double next next1"><input type="checkbox" id="restrict_double_next_1"></td>
              <td class="double next next2"><input type="checkbox" id="restrict_double_next_2"></td>
              <td class="double next next3"><input type="checkbox" id="restrict_double_next_3"></td>
              <td class="double next next4"><input type="checkbox" id="restrict_double_next_4"></td>
              <td class="double opposite">  <input type="checkbox" id="restrict_double_opposite"></td>
            </tr>
          </table>
        </div>

        <div class="clear_both"></div>

        <div id="imgmask_img_box" class="imgmask_img_hide optionbox obright hidden">
          <h3>Masked Location Bitmap</h3>
          <div class="clear_both"></div>
          <figure>
            <figcaption id="imgmask_img_caption">
              Original
              <br>
              <span class="imgmask_caption_size_hw">
                <code id="imgmask_img_size_width"></code>
                &nbsp;x&nbsp;
                <code id="imgmask_img_size_height"></code>
              </span>
            </figcaption>
          </figure>
          <figure>
            <figcaption id="imgmask_bitmap_caption">
              Bitmap
              <br>
              <span class="imgmask_caption_size_hw">
                <code id="imgmask_bitmap_size_width"></code>
                &nbsp;x&nbsp;
                <code id="imgmask_bitmap_size_height"></code>
              </span>
            </figcaption>
          </figure>
        </div>

        <div class="imgmaskbox optionbox obleft">
          <h3>Restricted Location Bitmap</h3>
          <table>
            <tr>
              <th>Enabled?</th>
              <td>
                <input id="imgmask_enabled" type="checkbox">
              </td>
            </tr>
            <tr>
              <th>Load Image File</th>
              <td>
                <input id="imgmask_file" type="file" accept="image/*">
                <button id="imgmask_file_button">Load image file...</button>
              </td>
            </tr>
            <tr>
              <th>Load Image URL</th>
              <td>
                <input id="imgmask_url" type="text" placeholder="https://example.com/..." spellcheck="false">
                <button id="imgmask_url_button">&#8658;</button>
              </td>
            </tr>
            <tr>
              <th>Load Image Example</th>
              <td>
                <select id="imgmask_example" name="imgmask_example">
                  <option value="" selected></option>
                  <option value="masks/circle.png">Circle</option>
                  <option value="masks/ring.png">Ring</option>
                  <option value="masks/ring-4star.png">Ring + 4-Star</option>
                </select>
                <button id="imgmask_example_button">&#8658;</button>
              </td>
            </tr>
            <tr>
              <th>Bitmap Threshold</th>
              <td>
                <input id="imgmask_threshold" type="range" value="1" min="1" max="254" step="1">
                <label for="imgmask_threshold">%</label>
              </td>
            </tr>
            <tr>
              <th>Bitmap Size</th>
              <td class="labeled_2d_number_input">
                <label for="imgmask_scale_width">L/R</label>
                <input id="imgmask_scale_width"
                       name="imgmask_scale_width"
                       type="number" value="50"
                       min="0" max="99" step="1">
                <span class="suffix">%</span>
                <label for="imgmask_scale_height">T/B</label>
                <input id="imgmask_scale_height"
                       name="imgmask_scale_height"
                       type="number" value="50"
                       min="0" max="99" step="1">
                <span class="suffix">%</span>
              </td>
            </tr>
            <tr>
              <th>Bitmap Offset</th>
              <td class="labeled_2d_number_input">
                <label for="imgmask_offset_x">+X</label>
                <input id="imgmask_offset_x" name="imgmask_offset_x"
                       type="number" value="0" step="1">
                <span class="suffix"></span>
                <label for="imgmask_offset_y">+Y</label>
                <input id="imgmask_offset_y" name="imgmask_offset_y"
                       type="number" value="0" step="1">
                <span class="suffix"></span>
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Multiply the size of the bitmap relative to the original image. You probably don't want this! In rare cases this might antialias images with a lot of mid-level luminosity, at the cost of a LOT of memory and CPU time whenever the bitmap is recalculated.">Bitmap Oversampling</th>
              <td class="labeled_2d_number_input">
                <span class="prefix"></span>
                <input id="imgmask_oversample" type="number" value="1" min="1" max="4" step="1">
                <span class="suffix">x</label>
              </td>
            </tr>
          </table>
        </div>

        <div class="clear_both"></div>
      </div>

      <div id="serializebox">
        <h3 id="serializebox_title" class="panel">Title</h3>
        <textarea id="serializebox_text"></textarea>
        <div class="ui panel">
          <div class="actionbuttons buttonbox">
            <button id="serializebox_action">Unknown Action</button>
            <button id="serializebox_cancel">Cancel</button>          
          </div>
        </div>
      </div>
    </div>

    <footer></footer>

    <script type="text/javascript">
undivert(`main.js')
    </script>
  </body>
</html>
