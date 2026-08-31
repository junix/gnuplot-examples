# 07 — Wi-Fi coverage over a floor plan, from a walk test.
#
# Subject: a 40 x 28 m open-plan office with three ceiling APs. An engineer
# walked a serpentine route with a survey tool and logged 35 RSSI readings;
# the job is to turn scattered samples into a coverage map and mark the
# -67 dBm (voice) and -75 dBm (data) design contours.
#
# Features: set dgrid3d ... gauss (scattered samples -> regular grid),
# set pm3d map with interpolate, set palette defined with dBm breakpoints
# (plus the rgbformulae alternative, kept as a comment), set cbrange and a
# labelled colorbox, set object rect / set object circle / set label ... point
# drawn front, and a contour overlay done the ONLY way that renders cleanly:
# margins locked 'at screen' BEFORE set multiplot, then a second pass with the
# colorbox, border, tics and title switched off. Contour LABELS need a third
# plot element, 'with labels nosurface' — set cntrlabel alone draws nothing.
#
# Because screen margins fix the aspect ratio here, do NOT also use
# 'set size ratio -1': the two mechanisms fight and the plot is clipped.

ap1x = 8.0;  ap1y = 21.0
ap2x = 31.0; ap2y = 21.0
ap3x = 19.0; ap3y = 7.0
hceil = 2.4                       # AP height above the handset, metres

# log-distance path loss: -40 dBm at 1 m, exponent 3.2, plus 8 dB extra
# through the lab partition in the south-east corner.
d3(ax, ay, xx, yy) = sqrt((xx-ax)**2 + (yy-ay)**2 + hceil**2)
pl(ax, ay, xx, yy) = -40.0 - 32.0*log10(d3(ax, ay, xx, yy))
lab(xx, yy) = (xx > 29.5 && yy < 9.0) ? 8.0 : 0.0
best(xx, yy) = (pl(ap1x,ap1y,xx,yy) > pl(ap2x,ap2y,xx,yy) \
                ? (pl(ap1x,ap1y,xx,yy) > pl(ap3x,ap3y,xx,yy) ? pl(ap1x,ap1y,xx,yy) : pl(ap3x,ap3y,xx,yy)) \
                : (pl(ap2x,ap2y,xx,yy) > pl(ap3x,ap3y,xx,yy) ? pl(ap2x,ap2y,xx,yy) : pl(ap3x,ap3y,xx,yy))) \
               - lab(xx, yy)

seed = rand(1337)
set print $walk
# serpentine walk, wall to wall, plus one reading in each corner so the
# gridded field covers the whole floor and not just the interior hull
do for [row=0:4] {
    yy = 1.0 + row*6.5
    do for [c=0:6] {
        xx = (row % 2 == 0) ? 1.0 + c*6.333 : 39.0 - c*6.333
        print sprintf("%.2f %.2f %.2f", xx, yy, best(xx, yy) + 1.5*invnorm(rand(0)))
    }
}
do for [cx in "0.15 39.85"] {
    do for [cy in "0.15 27.85"] {
        print sprintf("%s %s %.2f", cx, cy, best(cx+0, cy+0) + 1.5*invnorm(rand(0)))
    }
}
set print

stats $walk using 3 nooutput
n_samp = STATS_records
rssi_lo = STATS_min
rssi_hi = STATS_max

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 1000,700 transparent font ',11'
        set output 'out/07-wifi-rssi-floorplan.png'
    } else {
        set terminal svg size 1000,700 font 'sans,11'
        set output 'out/07-wifi-rssi-floorplan.svg'
    }

    # 780 x 546 px of plot area for a 40 x 28 m floor: exactly 1 px = 5.13 cm.
    # These four margins must be identical on both passes, which is why they
    # are set BEFORE 'set multiplot' and never touched again.
    set lmargin at screen 0.09
    set rmargin at screen 0.87
    set bmargin at screen 0.10
    set tmargin at screen 0.88

    set xrange [0:40]
    set yrange [0:28]
    set cbrange [-92:-52]
    set view map
    set dgrid3d 60,60 gauss 4
    set pm3d map interpolate 2,2
    unset key

    # breakpoints are given in dBm and must span exactly the cbrange above,
    # otherwise gnuplot rescales them and -67 stops meaning -67
    set palette defined (-92 '#6b1414', -82 '#b03a2e', -75 '#d1603d', \
                         -67 '#f2c14e', -60 '#a8cf5f', -56 '#4c9bd4', -52 '#1f4e79')
    # equivalent-in-spirit alternative, the classic formula triplet:
    #   set palette rgbformulae 33,13,10
    set cblabel 'best-server RSSI (dBm)' offset 1,0
    set cbtics 5

    set multiplot

    # ---- pass 1: the interpolated field ------------------------------------
    set title sprintf('walk test, 40 x 28 m office: %d samples, %.0f to %.0f dBm', \
                      n_samp, rssi_lo, rssi_hi)
    set xlabel 'x (m)'
    set ylabel 'y (m)'
    set xtics 0, 5
    set ytics 0, 5
    splot $walk using 1:2:3 with pm3d notitle

    # ---- pass 2: contours, walls and APs on top -----------------------------
    # Everything the first pass already drew must be switched off here, or it
    # is drawn a second time one pixel out and the figure looks doubled.
    unset colorbox
    unset border
    unset xtics
    unset ytics
    unset title
    unset xlabel
    unset ylabel

    set contour base
    unset surface
    set cntrparam levels discrete -67, -75
    set cntrlabel format '%.0f dBm' font ',9' start 25 interval 200

    # structure and fittings, all drawn front so the field never covers them
    set object 1 rect from 29.5, 0 to 40, 9 front fillstyle empty \
        border lc rgb '#333333' lw 2
    set object 2 rect from 0, 23.5 to 9, 28 front fillstyle empty \
        border lc rgb '#333333' lw 2
    set object 3 circle at 20, 15.5 size 2.4 front fillstyle empty \
        border lc rgb '#333333' lw 2
    set label 10 'lab / server room (+8 dB wall)' at 34.7, 4.5 center front font ',9'
    set label 11 'plant room' at 4.5, 25.7 center front font ',9'
    set label 12 'atrium' at 20, 15.5 center front font ',9'

    set label 1 'AP-1' at ap1x, ap1y point pt 7 ps 1.6 lc rgb '#111111' \
        offset 1.2,0.8 front
    set label 2 'AP-2' at ap2x, ap2y point pt 7 ps 1.6 lc rgb '#111111' \
        offset 1.2,0.8 front
    set label 3 'AP-3' at ap3x, ap3y point pt 7 ps 1.6 lc rgb '#111111' \
        offset 1.2,0.8 front

    # With 'unset surface' every element of this splot draws the CONTOUR, not
    # the data: 'with lines' is the contour itself and 'with labels' is what
    # actually prints the level on it.
    splot $walk using 1:2:3 with lines nosurface lw 2.5, \
          $walk using 1:2:3 with labels nosurface boxed

    unset multiplot

    # ---- put the state back for the next format ----------------------------
    unset contour
    set surface
    do for [o=1:3] { unset object o }
    do for [l=1:3]  { unset label l }
    do for [l=10:12] { unset label l }
    set border
    set colorbox
    unset output
}
