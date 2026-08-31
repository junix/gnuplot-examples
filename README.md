# gnuplot-examples

A feature tour of gnuplot 6, twelve scripts long, ordered from trivial to
advanced. Every script in `src/` is a self-contained figure about a real
subject — a latency log, an antenna pattern, a fibre link — chosen so that
the gnuplot features it needs are the ones the subject actually calls for.

Each script renders a transparent-background PNG **and** an SVG of the same
size and the same data into `out/`. Example 11 is the exception: it emits 36
animation frames as PNG only.

## Render

```sh
just build     # run every src/*.gp, writes out/*.png + out/*.svg
just test      # build, then verify every expected output exists
just gif       # combine animation frames into out/animation.gif (ffmpeg)
just clean     # empty out/
```

Or a single example:

```sh
gnuplot src/01-plot-basics.gp
gnuplot -e "nframes=60" -e "zmax=120" src/11-fiber-dispersion-frames.gp
```

## Examples

| # | Script | Subject | Features it integrates |
|---|--------|---------|------------------------|
| 01 | [01-plot-basics.gp](src/01-plot-basics.gp) | LC tank ring-down | the copy-paste entry point: transparent `pngcairo` + `svg` `replot` preamble, `with lines` (`lw`/`dt`), `with linespoints pt 7`, `'+'` pseudofile with `every`, `set grid xtics ytics mxtics mytics`, `set key box opaque`, `filledcurves above y1=0` / `below y1=0` |
| 02 | [02-latency-distribution.gp](src/02-latency-distribution.gp) | 6,000 requests against a search API | `set print $data` + `rand()`/`invnorm()` datablock generation, `stats ... nooutput` → `STATS_records/mean/median`, `smooth frequency` into log-spaced bins with a `bin()` function + `set boxwidth`, `smooth cumulative` on `axes x1y2`, `smooth kdensity` with a weight column, percentile `set arrow`/`set label`, `set style data boxplot` with the full `(x):(value):(width):(factor)` form, `set style boxplot outliers ... sorted`, `set jitter ... wrap` |
| 03 | [03-edge-latency-slo.gp](src/03-edge-latency-slo.gp) | CDN edge tier vs its latency SLO | 2-row multiplot with shared margins, `filledcurves` between two data columns as a p50–p99 band, `axes x1y2` boxes with an explicit `set y2range`, `set xdata time` / `timefmt` / `format x '%H:%M'`, `set object rect ... behind`, `set arrow ... heads front`, a dashed threshold, `filledcurves x1` burn-down |
| 04 | [04-cell-fade-arrhenius.gp](src/04-cell-fade-arrhenius.gp) | accelerated ageing of NMC 18650 cells | `fit ... using 1:2:3 yerrors via A, Ea` with `errorvariables` **and** `covariancevariables`, `set fit quiet ... logfile '/dev/null'`, `with yerrorbars`, `set logscale y`, a boxed `sprintf` label with `FIT_WSSR/FIT_NDF`, a ±1σ `filledcurves` band propagated through the covariance, an `x2` axis, an impulse residual panel against `set zeroaxis` |
| 05 | [05-generation-mix-stacked.gp](src/05-generation-mix-stacked.gp) | a grid's duck curve, 24 h at 5 min | stacked `filledcurves x1` from cumulative column expressions plotted **top band first**, `set style fill transparent solid noborder`, `set xdata time`, net load on `x1y2`, `set object rect` + two-headed `set arrow` with a `sprintf`'d ramp rate, `set key outside bottom center horizontal maxrows 2`, and a clustered `set style data histograms` panel of the same day |
| 06 | [06-yagi-radiation-pattern.gp](src/06-yagi-radiation-pattern.gp) | 7-element 435 MHz Yagi | `set polar` + `set angles degrees` + `set trange [0:360]` + high `set samples`, `set theta top clockwise`, `set rrange` with named rtics in dB, `set grid polar`, the `unset border`/`unset xtics`/`unset ytics`/`unset raxis` cleanup, `filledcurves above r=<const>`, a floor clamp against wrap-through-origin, polar rays via `set arrow`, and a full polar-state reset before an `x1y2` companion panel |
| 07 | [07-wifi-rssi-floorplan.gp](src/07-wifi-rssi-floorplan.gp) | Wi-Fi walk test over a floor plan | `set dgrid3d 60,60 gauss`, `set pm3d map interpolate`, `set palette defined` on dBm breakpoints (with the `set palette rgbformulae 33,13,10` alternative alongside), `set cbrange` + `set cblabel`, `set object rect`/`circle` and `set label ... point` drawn `front`, and the locked-`at screen`-margin two-pass contour overlay with `set contour base`, `unset surface`, `w lines nosurface` **and** `w labels nosurface` |
| 08 | [08-heatsink-thermal-field.gp](src/08-heatsink-thermal-field.gp) | pin-fin heatsink at 95 W | `splot` of an analytic surface with `set isosamples` and `set hidden3d`, `set pm3d depthorder`, base isotherms via `set contour base` + `set cntrparam levels incremental`, a `set view map` companion, matched `cbrange` with `set colorbox horizontal user origin ... size ...`, asymmetric multiplot from per-panel `set size`/`set origin`, `set xyplane at 0` |
| 09 | [09-hdd-weibull-reliability.gp](src/09-hdd-weibull-reliability.gp) | two 12 TB drive models | `set table $mr` / `plot ... with table` / `unset table` for Bernard median ranks (`$0` is the zero-based row index and restarts per `every` block), `set nonlinear y via ...` issued **after** `logscale`/`xrange`/`yrange`, named percentage ytics (`%%`-escaped), per-model `fit` with `errorvariables`, `plot for` over a `word()` list, `set object rect` warranty window |
| 10 | [10-servo-bode-margins.gp](src/10-servo-bode-margins.gp) | PI velocity loop of a servo | complex arithmetic with the `{0,1}` literal and `abs()`, an analytically unwrapped phase (never `arg()`), watchpoints `watch y=0` / `watch y=-180` harvested in a `set terminal unknown` pass before the format loop with every read guarded by `|WATCH_n| > 0`, `real()`/`imag()` on `WATCH_1[1]`, `set style watchpoints label boxed`, a `GPVAL_COMPILE_OPTIONS` fallback, 2-row log-decade multiplot with `mxtics 10` |
| 11 | [11-fiber-dispersion-frames.gp](src/11-fiber-dispersion-frames.gp) | a pulse dispersing along 80 km of SMF | **animation, PNG only**: `do for` frame loop with `sprintf`'d output paths, per-frame multiplot, complex field with `{0,1}` and `abs()**2`, `set table` over the `'+'` pseudofile followed by numerical differentiation of the phase, a datablock accumulated with `set print ... append`, frozen ranges, `exists()` guards on `nframes`/`zmax` |
| 12 | [12-lidar-voxel-isosurface.gp](src/12-lidar-voxel-isosurface.gp) | terrestrial LiDAR scan of a street corner | `set vgrid $occ size 60` with explicit `vxrange`/`vyrange`/`vzrange`, `vfill ... using x:y:z:(radius):(weight)`, `splot $occ with isosurface level ...`, `set pm3d depthorder` + `set style fill` + `set isosurface mixed`, colouring an isosurface through its **linetype** (`fc`/`lc`/palette are all ignored), a companion `lc palette` point cloud, matched `set view` and `set xyplane at 0` |

## Output preamble

Non-multiplot scripts set up the PNG, draw once, then re-emit as SVG with a
bare `replot`:

```gnuplot
set terminal pngcairo size 900,600 transparent font ',11'
set output 'out/01-plot-basics.png'
plot ...
set terminal svg size 900,600 font 'sans,11'
set output 'out/01-plot-basics.svg'
replot
```

`pngcairo` needs `transparent` spelled out; the `svg` terminal is transparent
by default.

**Multiplot scripts cannot use `replot`** — it is meaningless once
`set multiplot` has been issued — so they wrap the whole figure in a format
loop instead, which is why ten of these twelve files look like this:

```gnuplot
do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 1000,760 transparent font ',11'
        set output 'out/03-edge-latency-slo.png'
    } else {
        set terminal svg size 1000,760 font 'sans,11'
        set output 'out/03-edge-latency-slo.svg'
    }
    set multiplot
    ...
    unset multiplot
    unset output
}
```

Two consequences of that loop are worth stating out loud, because both bite
silently:

- **Build every datablock once, before the loop.** `set print $d` overwrites
  rather than appends, so re-running the generator is not what breaks — but
  `rand()` advances its internal state, so a generator run twice hands the SVG
  different data from the PNG.
- **Reset any state the last panel left behind.** `set logscale`, `set polar`,
  `set contour`, `set view map`, `at screen` margins and `set format x ''` all
  survive to the next iteration and land on the *first* panel of the next
  format. Several scripts here carry an explicit `unset` for exactly that.

Transparency survives multiplot: every PNG in `out/` is colour type 6 with a
fully transparent corner pixel.

## Notes

- Transparent backgrounds pair with the default dark text and axes, so the
  images are meant for **light** backgrounds. On a dark page, override the
  text and border colours (`set border lc rgb '#dddddd'`, `set key tc rgb
  '#dddddd'`, …) or drop `transparent` from the terminal line.
- Colours are written as 6-digit `#RRGGBB` everywhere. gnuplot accepts a
  3-digit `'#c44'` without a word of complaint and then renders a default
  linetype colour instead — always spell out all six digits.
- Random data is generated from a fixed seed (`rand(<non-zero>)`), so every
  render of a given script produces the same figure.
- `just build` is expected to print two `WARNING: Plotting with 'unknown'
  terminal` lines (example 10 harvesting its watchpoints) and a four-line
  `vfill` diagnostic (example 12). Neither is a failure.
- Everything under `out/` is generated and git-ignored.
- Environment: gnuplot 6.0 patchlevel 4 on Linux, built with `+OBJECTS
  +STATS +WATCHPOINTS +COMPLEX_FUNCS +POLARGRID` (check yours with
  `print GPVAL_COMPILE_OPTIONS`). Example 10 falls back to a bisection search
  when `+WATCHPOINTS` is missing; the rest of the tour needs the options above.
