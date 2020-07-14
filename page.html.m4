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
          <table id="restrict_table">
            <tr>
              <td class="blank"></td>
              <th scope="col" class="header prev prev3">-3</th>
              <th scope="col" class="header prev prev2">-2</th>
              <th scope="col" class="header prev prev1">-1</th>
              <th scope="col" class="header self">Self</th>
              <th scope="col" class="header next next1">+1</th>
              <th scope="col" class="header next next2">+2</th>
              <th scope="col" class="header next next3">+3</th>
              <th scope="col" class="header opposite">Opp</th>
            </tr>
            <tr>
              <th scope="row">Last</th>
              <td class="single prev prev3"><input type="checkbox" id="restrict_single_prev_3"></td>
              <td class="single prev prev2"><input type="checkbox" id="restrict_single_prev_2"></td>
              <td class="single prev prev1"><input type="checkbox" id="restrict_single_prev_1"></td>
              <td class="single self">      <input type="checkbox" id="restrict_single_self"></td>
              <td class="single next next1"><input type="checkbox" id="restrict_single_next_1"></td>
              <td class="single next next2"><input type="checkbox" id="restrict_single_next_2"></td>
              <td class="single next next3"><input type="checkbox" id="restrict_single_next_3"></td>
              <td class="single opposite">  <input type="checkbox" id="restrict_single_opposite"></td>
            </tr>
            <tr>
              <th scope="row" class="double">Last 2x</th> 
              <td class="double prev prev3"><input type="checkbox" id="restrict_double_prev_3"></td>
              <td class="double prev prev2"><input type="checkbox" id="restrict_double_prev_2"></td>
              <td class="double prev prev1"><input type="checkbox" id="restrict_double_prev_1"></td>
              <td class="double self">      <input type="checkbox" id="restrict_double_self"></td>
              <td class="double next next1"><input type="checkbox" id="restrict_double_next_1"></td>
              <td class="double next next2"><input type="checkbox" id="restrict_double_next_2"></td>
              <td class="double next next3"><input type="checkbox" id="restrict_double_next_3"></td>
              <td class="double opposite">  <input type="checkbox" id="restrict_double_opposite"></td>
            </tr>
          </table>
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