# Boxplot comparison
set terminal pngcairo size 800,600 transparent
set output 'out/11-boxplot.png'
set title 'Boxplots'
set style data boxplot
set style fill solid 0.5 border -1
set xlabel 'group'; set ylabel 'value'
$vals << EOD
1 10.1
1 11.3
1 9.8
1 12.0
1 10.7
2 14.2
2 13.9
2 15.1
2 14.8
2 13.5
EOD
plot $vals using (1):2 title 'A', \
     '' using (2):2 title 'B'

# also emit SVG
set terminal svg size 800,600
set output 'out/11-boxplot.svg'
replot
