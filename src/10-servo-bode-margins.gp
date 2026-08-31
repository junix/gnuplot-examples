# 10 — Bode plot and stability margins of a PI-controlled brushless servo.
#
# Subject: velocity loop of a 400 W brushless servo. Plant = one integrator,
# a mechanical pole at 125 rad/s, an electrical pole at 1667 rad/s and 300 us
# of PWM + sampling transport delay; controller = PI with Ti = 50 ms.
#
# Features: complex arithmetic with the {0,1} literal and abs() for the
# magnitude, watchpoints (watch y=0 on the magnitude, watch y=-180 on the
# phase) harvested in a 'set terminal unknown' pass BEFORE the format loop,
# set style watchpoints label boxed, a 2-row multiplot sharing a log-decade
# x axis with mxtics 10, and set arrow drawing each margin as a measured span.
#
# TWO traps this file exists to document:
#
#  1. NEVER use arg() for a phase trace. arg() returns the principal value, so
#     the curve jumps from -180 to +180 in the middle of the sweep, the plotted
#     phase is discontinuous, and 'watch y=-180' finds NOTHING. The phase here
#     is written out analytically term by term, so it is continuous by
#     construction and the watchpoint has something to hit.
#
#  2. A watchpoint only exists after the plot that carries it, so its value
#     cannot be read and used in the same figure. Harvest first, into a
#     throwaway 'unknown' terminal, then build the labels, then render. Guard
#     EVERY read with |WATCH_n| > 0: reading WATCH_1[1] of an empty array is a
#     fatal error and takes the whole build down with it.

j    = {0,1}
Kp   = 1.0                      # proportional gain
Ti   = 0.050                    # PI integral time, s
Kg   = 63.2                     # plant gain
Tm   = 0.008                    # mechanical pole, s   (125 rad/s)
Te    = 0.0006                  # electrical pole, s   (1667 rad/s)
tau  = 0.0003                   # transport delay, s
r2d  = 180.0/pi

# Open-loop transfer function, evaluated with complex arithmetic.
L(w) = Kp*(1.0 + 1.0/(j*w*Ti)) * Kg/(j*w*(1.0 + j*w*Tm)*(1.0 + j*w*Te)) \
       * exp(-j*w*tau)
magdb(w) = 20*log10(abs(L(w)))

# Analytically unwrapped phase: one term per factor, no wrapping anywhere.
ph(w) = r2d*(-atan(1.0/(w*Ti)) - pi/2.0 - atan(w*Tm) - atan(w*Te) - w*tau)

w_lo = 0.5
w_hi = 2000.0

# ---- harvest the two crossings --------------------------------------------
have_watch = strstrt(GPVAL_COMPILE_OPTIONS, '+WATCHPOINTS') > 0
wgc = NaN; wpc = NaN

if (have_watch) {
    set terminal unknown          # this prints a WARNING per plot; harmless
    set logscale x
    set xrange [w_lo:w_hi]
    set samples 4000

    plot magdb(x) watch y=0
    if (|WATCH_1| > 0) { wgc = real(WATCH_1[1]) }

    plot ph(x) watch y=-180
    if (|WATCH_1| > 0) { wpc = real(WATCH_1[1]) }
} else {
    # stock builds without +WATCHPOINTS: same answer, found by bisection
    a = w_lo; b = w_hi
    do for [i=1:80] { c = sqrt(a*b); if (magdb(c) > 0) { a = c } else { b = c } }
    wgc = sqrt(a*b)
    a = w_lo; b = w_hi
    do for [i=1:80] { c = sqrt(a*b); if (ph(c) > -180.0) { a = c } else { b = c } }
    wpc = sqrt(a*b)
}

pm = 180.0 + ph(wgc)            # phase margin, degrees
gm = -magdb(wpc)                # gain margin, dB

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 1000,780 transparent font ',11'
        set output 'out/10-servo-bode-margins.png'
    } else {
        set terminal svg size 1000,780 font 'sans,11'
        set output 'out/10-servo-bode-margins.svg'
    }

    set logscale x
    set xrange [w_lo:w_hi]
    set samples 4000
    set mxtics 10
    # Watchpoint labels are formatted with the axis tic formats, so blanking
    # the upper panel's x format ('set format x \'\'') would blank the x half
    # of its watch label too. Both panels keep their tic labels.
    set format x '%.0f'
    set format y '%.0f'
    set lmargin 12
    set rmargin 4
    set key off
    set style watchpoints label boxed point pt 7 ps 1.2 lc rgb '#a02323'
    set style textbox 1 opaque fc rgb '#ffffff' border lc rgb '#a02323'

    set multiplot

    # ---- magnitude ---------------------------------------------------------
    set origin 0.0, 0.46
    set size 1.0, 0.54
    set title 'brushless velocity loop, open-loop response' offset 0,-0.5
    set ylabel '|L| (dB)'
    set yrange [-70:60]
    set ytics -60, 20
    unset xlabel
    set grid xtics mxtics ytics lc rgb '#c8c8c8', lc rgb '#ececec'
    set zeroaxis lw 2 lc rgb '#999999'

    set arrow 1 from wpc, magdb(wpc) to wpc, 0 heads size screen 0.008,20 \
        lw 2.5 lc rgb '#54a24b' front
    set label 1 sprintf('gain margin %.1f dB', gm) \
        at wpc*1.12, magdb(wpc)/2.0 left front tc rgb '#3d7a35'
    set arrow 2 from wgc, graph 0 to wgc, graph 1 nohead lw 1.5 dt 3 \
        lc rgb '#888888' back
    set arrow 3 from wpc, graph 0 to wpc, graph 1 nohead lw 1.5 dt 3 \
        lc rgb '#888888' back

    plot magdb(x) with lines lw 2.5 lc rgb '#1f4e79' watch y=0

    # ---- phase --------------------------------------------------------------
    unset arrow 1
    unset label 1
    unset title
    set origin 0.0, 0.0
    set size 1.0, 0.46
    set xlabel 'frequency (rad/s)'
    set ylabel 'phase (deg)'
    set yrange [-260:-80]
    set ytics -240, 40

    set arrow 4 from wgc, ph(wgc) to wgc, -180 heads size screen 0.008,20 \
        lw 2.5 lc rgb '#e45756' front
    set label 2 sprintf('phase margin %.1f{/Symbol \260}', pm) \
        at wgc*1.22, ph(wgc) - 39.0 left front tc rgb '#a02323'
    set label 3 sprintf("gain crossover\n%.1f rad/s", wgc) \
        at wgc*0.85, -110 right front tc rgb '#333333'
    set label 4 sprintf("phase crossover\n%.0f rad/s", wpc) \
        at wpc*0.85, -240 right front tc rgb '#333333'

    plot ph(x) with lines lw 2.5 lc rgb '#1f4e79' watch y=-180

    unset arrow 2
    unset arrow 3
    unset arrow 4
    do for [l=2:4] { unset label l }
    unset zeroaxis
    unset multiplot
    unset output
}
