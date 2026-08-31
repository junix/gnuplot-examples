# 08 — thermal field of a pin-fin heatsink, three views of one model.
#
# Subject: a 60 x 60 mm pin-fin sink on a 95 W package, 1.2 m/s crossflow
# entering from x = 0. The air warms as it crosses the sink, so the hot spot
# sits downstream of the die and the 85 C base limit is broken by a few
# degrees at the worst point.
#
# Features: splot of an analytic surface with set isosamples and set hidden3d,
# set pm3d depthorder, base isotherms via set contour base with
# set cntrparam levels incremental, a second panel in set view map, matched
# cbrange across both 3D panels with the colorbox positioned by hand
# (set colorbox horizontal user origin ... size ...), an asymmetric multiplot
# built from per-panel set size / set origin, set xyplane at 0, and a 2D
# centreline profile with the limit dashed and the margin annotated.
#
# Note the explicit reset before the 2D panel: 'set view 60,30' and
# 'unset pm3d' / 'unset contour', or the map state from panel (b) leaks.

L    = 60.0                     # sink footprint, mm
Tin  = 26.0                     # inlet air temperature, C
Tlim = 85.0                     # base temperature limit

# Air warms along x; the die sits slightly upstream of centre; a shallow
# transverse term accounts for the unfinned edges running cooler.
T(x, y) = Tin + 12.0*(x/L) \
          + 53.0*exp(-((x-26.0)**2/(2*13.0**2) + (y-30.0)**2/(2*12.0**2))) \
          + 4.0*exp(-(y-30.0)**2/(2*22.0**2))

# centreline peak and where it happens
xpk = 0.0; Tpk = -1e9
do for [i=0:600] { xx = i/10.0; if (T(xx, 30.0) > Tpk) { Tpk = T(xx, 30.0); xpk = xx } }
margin = Tlim - Tpk             # negative: over the limit

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 1120,840 transparent font ',11'
        set output 'out/08-heatsink-thermal-field.png'
    } else {
        set terminal svg size 1120,840 font 'sans,11'
        set output 'out/08-heatsink-thermal-field.svg'
    }

    set xrange [0:L]
    set yrange [0:L]
    set zrange [0:95]
    set cbrange [26:90]                 # identical in both 3D panels
    set isosamples 60,60
    set samples 200
    set palette defined (26 '#2c5aa0', 45 '#4fb3bf', 62 '#f2c14e', \
                         76 '#e07b39', 90 '#8c1d1d')
    set cblabel 'base temperature (C)'
    set colorbox horizontal user origin 0.30, 0.365 size 0.42, 0.018
    unset key

    set multiplot

    # ---- (a) the surface itself ---------------------------------------------
    # panel (b) below pins its margins 'at screen'; clear them again here or
    # the second format inherits panel (b)'s frame for panel (a).
    unset lmargin
    unset rmargin
    unset bmargin
    unset tmargin
    set lmargin 9
    set rmargin 2
    set origin 0.0, 0.41
    set size 0.56, 0.59
    set title '(a) base temperature field, 95 W at 1.2 m/s' offset 0,-1
    set view 58, 32, 1.10, 1.0
    set xyplane at 0                    # drop the floor onto z = 0
    set hidden3d
    set pm3d depthorder
    set style fill solid 1.0
    set contour base                    # 'set contour surface' draws them on
    set cntrparam levels incremental 30, 10, 90   # the surface instead
    set cntrparam bspline
    set xlabel 'x (mm), flow direction' offset 0,-0.5
    set ylabel 'y (mm)' offset 1,0
    set zlabel 'T (C)' rotate by 90 offset 1,0
    set xtics 0, 20 offset 0,-0.3
    set ytics 0, 20
    set ztics 0, 20
    set grid ztics lc rgb '#d0d0d0'

    splot T(x,y) with pm3d notitle

    # ---- (b) the same field seen from above ---------------------------------
    unset contour
    set origin 0.56, 0.41
    set size 0.44, 0.59
    set title '(b) the same field from above' offset 0,-1
    set view map
    set isosamples 80,80
    unset hidden3d
    unset zlabel
    unset ztics
    set pm3d map
    set xlabel 'x (mm)' offset 0,0.4
    set ylabel 'y (mm)'
    set lmargin at screen 0.63
    set rmargin at screen 0.95
    set bmargin at screen 0.47
    set tmargin at screen 0.95

    set object 1 rect from 18, 20 to 34, 40 front fillstyle empty \
        border lc rgb '#ffffff' lw 2
    set label 1 'die footprint' at 26, 42 center front tc rgb '#ffffff'
    set arrow 1 from 2, 54 to 14, 54 head filled size 3,20 lw 3 lc rgb '#ffffff' front
    set label 2 'air, 1.2 m/s' at 16, 54 left front tc rgb '#ffffff'

    splot T(x,y) with pm3d notitle

    # ---- (c) centreline profile ---------------------------------------------
    unset object 1
    unset label 1
    unset label 2
    unset arrow 1
    set view 58, 32, 1.05, 1.0          # put the 3D view back for the next format
    unset pm3d
    unset colorbox
    set origin 0.0, 0.0
    set size 1.0, 0.30
    set isosamples 60,60
    unset lmargin
    unset rmargin
    unset bmargin
    unset tmargin
    set lmargin 10
    set rmargin 6
    set title '(c) profiles along the flow' offset 0,-0.7
    set xlabel 'x (mm), flow direction'
    set ylabel 'T (C)'
    set yrange [14:100]
    set ytics 30, 20
    set mytics 2
    set grid xtics ytics lc rgb '#d8d8d8'
    set key at graph 0.5, 0.02 center bottom horizontal box opaque samplen 2

    set arrow 2 from xpk, Tpk to xpk, Tlim heads size 2,20 lw 2 lc rgb '#a02323' front
    set label 3 sprintf('peak %.1f C at x = %.0f mm: %.1f C OVER the %.0f C limit', \
                        Tpk, xpk, -margin, Tlim) \
        at xpk + 2, 95 left front tc rgb '#a02323'

    plot Tlim with lines lw 2 dt 2 lc rgb '#a02323' title 'base limit 85 C', \
         T(x, 30.0) with lines lw 3 lc rgb '#8c1d1d' title 'centreline, y = 30 mm', \
         T(x,  8.0) with lines lw 3 dt 4 lc rgb '#2c5aa0' title 'edge, y = 8 mm'

    unset arrow 2
    unset label 3
    unset multiplot
    set colorbox
    unset output
}
