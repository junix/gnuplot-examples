# Basic line plot of a function
set terminal pngcairo size 800,600 transparent
set output 'out/01-basic-line.png'
set title 'Basic Line Plot'
set xlabel 'x'
set ylabel 'sin(x) / cos(x)'
set grid
plot sin(x) with lines lw 2 title 'sin(x)', \
     cos(x) with lines lw 2 dt 2 title 'cos(x)'

# also emit SVG (svg terminal background is transparent by default)
set terminal svg size 800,600
set output 'out/01-basic-line.svg'
replot
