# 3D surface plot
set terminal pngcairo size 800,600 transparent
set output 'out/05-3d-surface.png'
set title '3D Surface'
set xlabel 'x'; set ylabel 'y'; set zlabel 'z'
set isosamples 40
set hidden3d
set pm3d
splot x*x - y*y notitle

# also emit SVG
set terminal svg size 800,600
set output 'out/05-3d-surface.svg'
replot
