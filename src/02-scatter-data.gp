# Scatter plot from a data file (generated inline via a system call)
set terminal pngcairo size 800,600 transparent
set output 'out/02-scatter-data.png'
set title 'Scatter Plot from Data'
set xlabel 'x'
set ylabel 'y'
set grid
# demo data: deterministic pseudo-random scatter
set samples 200
seed = rand(7)
plot '+' using 1:(sin($1)*5 + rand(0)*2) with points pt 7 ps 0.8 title 'samples'

# also emit SVG; reseed so it matches the PNG exactly
set terminal svg size 800,600
set output 'out/02-scatter-data.svg'
seed = rand(7)
replot
