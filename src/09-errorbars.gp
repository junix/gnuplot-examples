# Error bars from inline data
set terminal pngcairo size 800,600 transparent
set output 'out/09-errorbars.png'
set title 'Points with Error Bars'
set xlabel 'x'; set ylabel 'y with uncertainty'
set grid
$data << EOD
1 1.1 0.2
2 2.4 0.3
3 3.9 0.25
4 8.2 0.5
5 10.1 0.4
EOD
plot $data using 1:2:3 with yerrorbars pt 7 lc rgb '#4c78a8' title 'measurement'

# also emit SVG
set terminal svg size 800,600
set output 'out/09-errorbars.svg'
replot
