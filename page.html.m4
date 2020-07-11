<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Integer Sequences</title>
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

    <div id="content">
      <div class="graph panel">
        <div id="graph_wrapper" class="canvas_wrapper canvas_size">
          <canvas id="graph" class="graph_canvas canvas_size" width="420" height="320">
            This requires a browser that supports the &lt;canvas&gt; tag.
          </canvas>
          <canvas id="graph_ui" class="graph_canvas canvas_size" width="420" height="320">
            This requires a browser that supports the &lt;canvas&gt; tag.
          </canvas>
        </div>
      </div>

      <div class="info panel">
        <table id="misc_info_table">
          <tr>
            <th>Current Location</th>
            <td id="point_cur_x"></td>
            <td id="point_cur_y"></td>
          </tr>
          <tr>
            <th>Total Steps</th>
            <td id="total_steps" colspan=2></td>
          </tr>
          <tr>
            <th>Steps / Frame</th>
            <td colspan=2>
              <input type="number" id="steps_per_frame"
                     min="0" max="500" step="10">
            </td>
          </tr>
        </table>
        <table id="point_pos_table">
          <tr>
            <th>P</th>
            <th>Color</th>
            <th>X</th>
            <th>Y</th>
            <th>Move %</th>
            <th></th>
          </tr>
        </table>
      </div>

      <div class="ui panel">
        <div class="runbox buttonbox">
          <button id="button_reset">Reset</button>
          <button id="button_step">Step</button>
          <button id="button_run">Run</button>
        </div>

        <div class="imgbox buttonbox">
          <button id="button_create_png">Create PNG</button>
          <button id="button_save">Save</button>
          <button id="button_load">Load</button>
        </div>

        <div class="pointsbox buttonbox">
          <span class="title">Points</span>
          <label for="num_points">N =</label>
          <input type="number" id="num_points" value="3"
                 min="3" max="8" step="1">
          <span class="title">Move All</span>
          <button id="move_all_reg_polygon">Reg. Polygon</button>
          <button id="move_all_random">Random</button>
        </div>

        <hr>
        <h3>Restrictions</h3>

        <div class="single restrictbox buttonbox">
          <h4>Last Target</h4>
          <ul>
            <li>
              <input type="checkbox" class="self" id="restrict_single_self">
              <label for="restrict_single_self" class="self">Self</label>
            </li>
            <li>
              <input type="checkbox" class="next" id="restrict_single_next">
              <label for="restrict_single_next" class="next">Neighbor (next)</label>
            </li>
            <li>
              <input type="checkbox" class="prev" id="restrict_single_prev">
              <label for="restrict_single_prev" class="prev">Neighbor (prev)</label>
            </li>
            <li>
              <input type="checkbox" class="opposite" id="restrict_single_opposite">
              <label for="restrict_single_opposite" class="opposite">Opposite</label>
            </li>
          </ul>
        </div>

        <div class="double restrictbox buttonbox">
          <h4>Last Target Selected Twice</h4>
          <ul>
            <li>
              <input type="checkbox" class="self" id="restrict_double_self">
              <label for="restrict_double_self" class="self">Self</label>
            </li>
            <li>
              <input type="checkbox" class="next" id="restrict_double_next">
              <label for="restrict_double_next" class="next">Neighbor (next)</label>
            </li>
            <li>
              <input type="checkbox" class="prev" id="restrict_double_prev">
              <label for="restrict_double_prev" class="prev">Neighbor (prev)</label>
            </li>
            <li>
              <input type="checkbox" class="opposite" id="restrict_double_opposite">
              <label for="restrict_double_opposite" class="opposite">Opposite</label>
            </li>
          </ul>
        </div>
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
