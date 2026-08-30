# Transparent-background PNG: add `transparent` to the terminal line
set terminal pngcairo size 800,600 transparent
set output 'out/13-transparent-png.png'
set title 'Transparent Background'
set xlabel 'x'; set ylabel 'sin(x)'
set key top right
unset border
set grid
plot sin(x) w l lw 3 lc rgb '#4c78a8' t 'sin(x)', \
     cos(x) w l lw 3 dt 2 lc rgb '#e07a5f' t 'cos(x)'

# also emit SVG (svg background is transparent by default)
set terminal svg size 800,600
set output 'out/13-transparent-png.svg'
replot
