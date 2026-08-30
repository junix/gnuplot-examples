# Histogram (smooth frequency) of a Gaussian sample
set terminal pngcairo size 800,600 transparent
set output 'out/03-histogram.png'
set title 'Histogram of Gaussian Samples'
set xlabel 'value'
set ylabel 'count'
set grid
set samples 5000
binwidth = 0.2
set boxwidth binwidth
bin(x) = floor(x/binwidth)*binwidth + binwidth/2.0
seed = rand(7)
plot '+' using (bin(invnorm(rand(0)))):(1) smooth frequency with boxes fc '#4c78a8' title 'counts'

# also emit SVG; reseed so it matches the PNG exactly
set terminal svg size 800,600
set output 'out/03-histogram.svg'
seed = rand(7)
replot
