# Filled curve / area between bounds
set terminal pngcairo size 800,600 transparent
set output 'out/07-fill-between.png'
set title 'Filled Curves'
set grid
plot sin(x) w filledcurves above y1=0 fc '#7fbf7f' t 'sin > 0', \
     sin(x) w filledcurves below y1=0 fc '#e07a5f' t 'sin < 0'

# also emit SVG
set terminal svg size 800,600
set output 'out/07-fill-between.svg'
replot
