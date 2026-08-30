# Heatmap with palette
set terminal pngcairo size 800,600 transparent
set output 'out/06-pm3d-heatmap.png'
set title 'Heatmap (pm3d map)'
set xlabel 'x'; set ylabel 'y'
set view map
set palette rgb 33,13,10
set isosamples 60
splot sin(x)*cos(y) notitle with pm3d

# also emit SVG
set terminal svg size 800,600
set output 'out/06-pm3d-heatmap.svg'
replot
