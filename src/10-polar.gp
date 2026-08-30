# Polar plot
set terminal pngcairo size 700,700 transparent
set output 'out/10-polar.png'
set title 'Polar Plot: rose curves'
set polar
set grid polar
set samples 400
unset raxis
plot 1+2*cos(4*t) w l lw 2 lc rgb '#4c78a8' t 'r = 1+2cos(4t)', \
     2*sin(3*t) w l lw 2 lc rgb '#e07a5f' t 'r = 2sin(3t)'

# also emit SVG (while polar mode is still active, so replot matches)
set terminal svg size 700,700
set output 'out/10-polar.svg'
replot

unset polar
