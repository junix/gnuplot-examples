# gnuplot-examples

A collection of gnuplot 6 examples. Each script in `src/` renders a
transparent-background PNG **and** an SVG (same size, same data) into `out/`:
PNG uses `terminal pngcairo ... transparent`; the `svg` terminal is
transparent by default. Example 12 (animation frames) is PNG-only.

## Render

```sh
just build     # run every src/*.gp, writes out/*.png + out/*.svg
just test      # build, then verify every expected output exists
just gif       # combine animation frames into out/animation.gif (ffmpeg)
```

Or a single example:

```sh
gnuplot src/01-basic-line.gp
```

## Examples

| # | Script | Demonstrates |
|---|--------|--------------|
| 01 | [src/01-basic-line.gp](src/01-basic-line.gp) | Line plots of functions, legend, grid |
| 02 | [src/02-scatter-data.gp](src/02-scatter-data.gp) | Scatter plot from pseudo-data via `'+'` |
| 03 | [src/03-histogram.gp](src/03-histogram.gp) | Binned histogram with `smooth frequency` |
| 04 | [src/04-multiplot.gp](src/04-multiplot.gp) | 2×2 multiplot layout (rendered per format) |
| 05 | [src/05-3d-surface.gp](src/05-3d-surface.gp) | 3D surface with `hidden3d` + `pm3d` |
| 06 | [src/06-pm3d-heatmap.gp](src/06-pm3d-heatmap.gp) | Heatmap via `set view map` and palette |
| 07 | [src/07-fill-between.gp](src/07-fill-between.gp) | Filled curves above/below a threshold |
| 08 | [src/08-log-scale.gp](src/08-log-scale.gp) | Log-log axes |
| 09 | [src/09-errorbars.gp](src/09-errorbars.gp) | Error bars with inline heredoc data (`<<EOD`) |
| 10 | [src/10-polar.gp](src/10-polar.gp) | Polar coordinates, rose curves |
| 11 | [src/11-boxplot.gp](src/11-boxplot.gp) | Boxplots with `set style data boxplot` |
| 12 | [src/12-animation-frames.gp](src/12-animation-frames.gp) | Animation frame generation with `do for` loop |
| 13 | [src/13-transparent-png.gp](src/13-transparent-png.gp) | Transparent-background output (PNG + SVG) |

## Notes

- Random-data examples (02, 03) reseed with `rand(7)` before each render so
  the PNG and SVG show identical data.
- Transparent background pairs with the default dark text — place on light
  backgrounds, or override text/line colors for dark ones.
- gnuplot was installed via Homebrew (`brew install gnuplot`), version 6.0.5.
