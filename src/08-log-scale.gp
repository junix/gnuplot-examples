# Log-scale axes
set terminal pngcairo size 800,600 transparent
set output 'out/08-log-scale.png'
set title 'Log-Log Plot'
set logscale xy 10
set xlabel 'x'; set ylabel 'x^2'
set grid xtics ytics mxtics mytics
plot [1:100] x**2 w lp lw 2 pt 7 t 'x^2'

# also emit SVG
set terminal svg size 800,600
set output 'out/08-log-scale.svg'
replot
