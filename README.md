# stochastic_sierpinski
Interactive "[Chaos Game](https://en.wikipedia.org/wiki/Chaos_game)" ([IFS](https://en.wikipedia.org/wiki/Iterated_function_system)) fractal generator in a self-contained HTML5 page.

## Usage

Try it live on GitHub:

[https://pages.codeberg.org/pdkl95/stochastic_sierpinski/](https://pages.codeberg.org/pdkl95/stochastic_sierpinski/)

## What is the Chaos Game?

The "Chaos Game" is a stochastic method of rendering a fractal. The general method is:

1. Create a set of points at different locations.

2. Set a cursor at any initial position. (if the starting position is not on the fractal, the first few points drawn will be incorrect while the cursor moves toward the fractal's attractor)

3. Choose a random target point from the given set of points.

    a. Move the cursor a fraction (usually 50%) of the way toward the target point.

    b. Draw a dot onto the output image at the cursor's new location.

4. Iterate step #3 until the fractal appears.

Using 3 points and movement fraction of 50% produces the [Sierpinski triangle](https://en.wikipedia.org/wiki/Sierpinski_triangle).

Numberphile has a [good explanation](https://www.youtube.com/watch?v=kbKtFN71Lfs) of the Chaos Game.

## Examples

* [Sierpinski triangle](https://pages.codeberg.org/pdkl95/stochastic_sierpinski/#{%22points%22:[{%22name%22:%22A%22,%22x%22:211,%22y%22:41.1923788646684,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#ff0000%22},{%22name%22:%22B%22,%22x%22:403,%22y%22:376.1923788646684,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#00ff00%22},{%22name%22:%22C%22,%22x%22:17,%22y%22:377.1923788646684,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#0000ff%22}],%22restrictions%22:{%22single%22:[],%22double%22:[]},%22options%22:{%22canvas_width%22:420,%22canvas_height%22:420,%22lock_aspect%22:true,%22draw_opacity%22:35,%22draw_style%22:%22color_blend_prev_color%22,%22data_source%22:%22dest%22,%22all_points_move_perc%22:50,%22move_absolute_magnitude%22:100,%22move_range_min%22:0,%22move_range_max%22:100,%22imgmask%22:{%22enabled%22:false,%22threshold%22:1,%22oversample%22:1,%22scale%22:{%22width%22:50,%22height%22:50},%22offset%22:{%22x%22:0,%22y%22:0}}}})

### Restricted Target Choice

Interesting variations are possible by limiting which points can be randomly selected as the target. In the current implementation, the restrictions are always relative to the last target point. The "2x" row is used when the last point was chosen twice in a row.

In these two examples, the point **opp**osite the last target point cannot be randomly selected as the next target.

* [classic square fractal](https://pages.codeberg.org/pdkl95/stochastic_sierpinski/#{%22points%22:[{%22name%22:%22A%22,%22x%22:419.5,%22y%22:1.5,%22move_perc%22:50,%22color%22:%22#ff0000%22},{%22name%22:%22B%22,%22x%22:419.5,%22y%22:419.5,%22move_perc%22:50,%22color%22:%22#80ff00%22},{%22name%22:%22C%22,%22x%22:1.5,%22y%22:419.5,%22move_perc%22:50,%22color%22:%22#00ffff%22},{%22name%22:%22D%22,%22x%22:1.5,%22y%22:1.5,%22move_perc%22:50,%22color%22:%22#7f00ff%22}],%22restrictions%22:{%22single%22:[%22prev3%22,%22next3%22,%22opposite%22],%22double%22:[]},%22options%22:{%22canvas_width%22:420,%22canvas_height%22:420,%22draw_style%22:%22color_blend_prev_color%22,%22draw_opacity%22:35}})
* [trapezoid](https://pages.codeberg.org/pdkl95/stochastic_sierpinski/#{%22points%22:[{%22name%22:%22A%22,%22x%22:398,%22y%22:341,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#ff0000%22},{%22name%22:%22B%22,%22x%22:304,%22y%22:59,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#80ff00%22},{%22name%22:%22C%22,%22x%22:116,%22y%22:59,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#00ffff%22},{%22name%22:%22D%22,%22x%22:22,%22y%22:341,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#7f00ff%22}],%22restrictions%22:{%22single%22:[%22opposite%22],%22double%22:[]},%22options%22:{%22canvas_width%22:420,%22canvas_height%22:420,%22lock_aspect%22:true,%22draw_opacity%22:35,%22draw_style%22:%22color_blend_prev_target%22,%22data_source%22:%22dest%22,%22all_points_move_perc%22:50,%22move_absolute_magnitude%22:100,%22move_range_min%22:0,%22move_range_max%22:100,%22imgmask%22:{%22enabled%22:false,%22threshold%22:1,%22oversample%22:1,%22scale%22:{%22width%22:50,%22height%22:50},%22offset%22:{%22x%22:0,%22y%22:0}}}})

In this more complicated example, the points +/- 1 and +/- 3 steps away from the last target point (the target's neighbors and the opposite point's neighbors) cannot be randomly selected as the next target. Additionally the current target cannot be selected again if it has been the target twice in a row.

* [flowery septagon](https://pages.codeberg.org/pdkl95/stochastic_sierpinski/#{%22points%22:[{%22name%22:%22A%22,%22x%22:211,%22y%22:10,%22move_perc%22:%2250%22,%22color%22:%22#ff0000%22},{%22name%22:%22B%22,%22x%22:366,%22y%22:86,%22move_perc%22:%2250%22,%22color%22:%22#ffdb00%22},{%22name%22:%22C%22,%22x%22:404,%22y%22:254,%22move_perc%22:%2250%22,%22color%22:%22#49ff00%22},{%22name%22:%22D%22,%22x%22:296,%22y%22:390,%22move_perc%22:%2250%22,%22color%22:%22#00ff92%22},{%22name%22:%22E%22,%22x%22:124,%22y%22:390,%22move_perc%22:%2250%22,%22color%22:%22#0092ff%22},{%22name%22:%22F%22,%22x%22:16,%22y%22:254,%22move_perc%22:%2250%22,%22color%22:%22#4900ff%22},{%22name%22:%22G%22,%22x%22:54,%22y%22:86,%22move_perc%22:%2250%22,%22color%22:%22#ff00db%22}],%22restrictions%22:{%22single%22:[%22prev1%22,%22prev3%22,%22next1%22,%22next3%22],%22double%22:[%22self%22]},%22options%22:{%22canvas_width%22:420,%22canvas_height%22:420,%22draw_style%22:%22color_blend_prev_color%22,%22draw_opacity%22:25}})

### Absolute Movement

Movement towards a point can be an absolute distance instead of the usual fractional (e.g, 50%) distance.

* [absolute movement toward a point](https://pages.codeberg.org/pdkl95/stochastic_sierpinski/#{%22points%22:[{%22name%22:%22A%22,%22x%22:210,%22y%22:212,%22move_perc%22:%22200%22,%22move_mode%22:%22absolute%22,%22color%22:%22#ff0000%22},{%22name%22:%22B%22,%22x%22:399,%22y%22:400,%22move_perc%22:%2250%22,%22move_mode%22:%22percent%22,%22color%22:%22#00ff00%22},{%22name%22:%22C%22,%22x%22:20,%22y%22:400,%22move_perc%22:%2250%22,%22move_mode%22:%22percent%22,%22color%22:%22#0000ff%22}],%22restrictions%22:{%22single%22:[],%22double%22:[]},%22options%22:{%22canvas_width%22:420,%22canvas_height%22:420,%22draw_opacity%22:35,%22draw_style%22:%22mono%22,%22data_source%22:%22dest%22,%22all_points_move_perc%22:%2250%22,%22move_absolute_magnitude%22:100,%22move_range_min%22:%220%22,%22move_range_max%22:%22200%22}})
* [absolute movement away from a point](https://pages.codeberg.org/pdkl95/stochastic_sierpinski/#{%22points%22:[{%22name%22:%22A%22,%22x%22:210,%22y%22:130,%22move_perc%22:%22200%22,%22move_mode%22:%22absolute%22,%22color%22:%22#ff0000%22},{%22name%22:%22B%22,%22x%22:360,%22y%22:340,%22move_perc%22:%2250%22,%22move_mode%22:%22percent%22,%22color%22:%22#00ff00%22},{%22name%22:%22C%22,%22x%22:60,%22y%22:340,%22move_perc%22:%2250%22,%22move_mode%22:%22percent%22,%22color%22:%22#0000ff%22}],%22restrictions%22:{%22single%22:[],%22double%22:[]},%22options%22:{%22canvas_width%22:420,%22canvas_height%22:420,%22draw_opacity%22:30,%22draw_style%22:%22mono%22,%22data_source%22:%22orig%22,%22all_points_move_perc%22:%2250%22,%22move_absolute_magnitude%22:100,%22move_range_min%22:%220%22,%22move_range_max%22:%22200%22}})

### Forbidding Movement With A Mask

An image can be used to generate a bitmap mask of forbidden locations for movement. The cursor cannot move onto any masked (black) location. If the movement towards a target point is forbidden, that point is temporarily removed from the set of possible target points and a new point is randomly selected as the target. _If all points are removed (all possible moves are forbidden), the rendering iteration **stops**!_ Note: if the mask has a lot of complex and/or small details, a very large number of iterations may be required befor the full fractal effects are visible. Also, lowering the draw opacity with more iterations can improve rendering of smaller details.

* [masking movement targets with an image](https://pages.codeberg.org/pdkl95/stochastic_sierpinski/#{%22points%22:[{%22name%22:%22A%22,%22x%22:211,%22y%22:41.1923788646684,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#ff0000%22},{%22name%22:%22B%22,%22x%22:403,%22y%22:376.1923788646684,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#00ff00%22},{%22name%22:%22C%22,%22x%22:17,%22y%22:377.1923788646684,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#0000ff%22}],%22restrictions%22:{%22single%22:[],%22double%22:[]},%22options%22:{%22canvas_width%22:420,%22canvas_height%22:420,%22lock_aspect%22:true,%22draw_opacity%22:35,%22draw_style%22:%22color_blend_prev_color%22,%22data_source%22:%22dest%22,%22all_points_move_perc%22:50,%22move_absolute_magnitude%22:100,%22move_range_min%22:0,%22move_range_max%22:100,%22imgmask%22:{%22enabled%22:true,%22threshold%22:1,%22oversample%22:1,%22scale%22:{%22width%22:34,%22height%22:34},%22offset%22:{%22x%22:0,%22y%22:55},%22mask_image_url%22:%22masks/circle.png%22}}})
* [eight sided lace from a circular mask](https://pages.codeberg.org/pdkl95/stochastic_sierpinski/#{%22points%22:[{%22name%22:%22A%22,%22x%22:321,%22y%22:10,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#ff0000%22},{%22name%22:%22B%22,%22x%22:539,%22y%22:101,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#ffbf00%22},{%22name%22:%22C%22,%22x%22:630,%22y%22:320,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#80ff00%22},{%22name%22:%22D%22,%22x%22:539,%22y%22:539,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#00ff40%22},{%22name%22:%22E%22,%22x%22:321,%22y%22:630,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#00ffff%22},{%22name%22:%22F%22,%22x%22:101,%22y%22:539,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#0040ff%22},{%22name%22:%22G%22,%22x%22:10,%22y%22:323,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#7f00ff%22},{%22name%22:%22H%22,%22x%22:101,%22y%22:101,%22move_perc%22:50,%22move_mode%22:%22percent%22,%22color%22:%22#ff00bf%22}],%22restrictions%22:{%22single%22:[%22prev2%22,%22next2%22,%22opposite%22],%22double%22:[%22prev1%22,%22prev3%22,%22next1%22,%22next3%22]},%22options%22:{%22canvas_width%22:640,%22canvas_height%22:640,%22lock_aspect%22:true,%22draw_opacity%22:35,%22draw_style%22:%22color_blend_prev_color%22,%22data_source%22:%22dest%22,%22all_points_move_perc%22:50,%22move_absolute_magnitude%22:100,%22move_range_min%22:0,%22move_range_max%22:100,%22imgmask%22:{%22enabled%22:true,%22threshold%22:177,%22oversample%22:1,%22scale%22:{%22width%22:48,%22height%22:48},%22offset%22:{%22x%22:0,%22y%22:0},%22mask_image_url%22:%22masks/circle.png%22}}})

## Resources

https://en.wikipedia.org/wiki/Chaos_game

https://en.wikipedia.org/wiki/Iterated_function_system

https://beltoforion.de/en/recreational_mathematics/chaos_game.php

https://resources.wolframcloud.com/FunctionRepository/resources/GeneralizedChaosGame

https://www.youtube.com/watch?v=kbKtFN71Lfs

## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
