# 01 — plot basics: the smallest complete script in this repo, and the
# copy-paste index for everything that follows.
#
# Subject: a damped LC ring-down probed on a scope — v(t) = A e^(-t/tau) cos(2 pi f t).
#
# Features: transparent pngcairo + svg 'replot' preamble (the standard
# non-multiplot output idiom), with lines (lw / dt), with linespoints pt 7,
# set grid xtics ytics mxtics mytics, set key box opaque, and
# filledcurves above y1=<const> / below y1=<const> to shade the sign of a signal.

A    = 1.8      # ring-down amplitude at t = 0, volts
tau  = 3.2      # envelope decay time constant, seconds
freq = 0.75     # ring frequency, Hz

v(t)   = A*exp(-t/tau)*cos(2*pi*freq*t)
env(t) = A*exp(-t/tau)

# ---- output preamble -------------------------------------------------------
# pngcairo needs 'transparent' spelled out; the svg terminal is transparent
# by default. Everything after this point is shared by both formats, so the
# SVG is produced with a bare 'replot' at the end of the file.
set terminal pngcairo size 900,600 transparent font ',11'
set output 'out/01-plot-basics.png'

set title 'LC tank ring-down: 1.8 V initial, 3.2 s decay, 0.75 Hz'
set xlabel 'time (s)'
set ylabel 'probe voltage (V)'

set xrange [0:10]
set yrange [-2.0:2.0]
set samples 1000

set mxtics 5
set mytics 2
set grid xtics ytics mxtics mytics lc rgb '#c8c8c8' lw 1, lc rgb '#e4e4e4' lw 1

set key box opaque top right samplen 2

set style fill transparent solid 0.30 noborder

plot v(x) with filledcurves above y1=0 lc rgb '#4c78a8' title 'v > 0', \
     v(x) with filledcurves below y1=0 lc rgb '#e45756' title 'v < 0', \
     env(x)  with lines lw 2 dt 2 lc rgb '#54a24b' title 'envelope +/- A e^{-t/{/Symbol t}}', \
     -env(x) with lines lw 2 dt 2 lc rgb '#54a24b' notitle, \
     v(x) with lines lw 2.5 lc rgb '#2b2b2b' title 'v(t)', \
     '+' using 1:(v($1)) every 25 \
        with linespoints pt 7 ps 0.8 lw 1 lc rgb '#f58518' title 'scope samples (every 25th)'

# ---- second format ---------------------------------------------------------
set terminal svg size 900,600 font 'sans,11'
set output 'out/01-plot-basics.svg'
replot
unset output
