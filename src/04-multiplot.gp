# Multiplot layout: 2x2 panels, rendered twice (transparent PNG + SVG)
do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 900,700 transparent
        set output 'out/04-multiplot.png'
    } else {
        set terminal svg size 900,700
        set output 'out/04-multiplot.svg'
    }
    set title 'Multiplot Demo'
    set multiplot layout 2,2 title 'Four Panels'
    set grid
    plot sin(x) w l lw 2 t 'sin'
    plot cos(x) w l lw 2 t 'cos'
    plot sin(2*x) w l lw 2 t 'sin(2x)'
    plot cos(2*x) w l lw 2 t 'cos(2x)'
    unset multiplot
}
