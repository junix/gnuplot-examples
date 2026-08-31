# 12 — voxel grids and isosurfaces from a terrestrial LiDAR scan.
#
# Subject: one tripod position of a terrestrial laser scanner on a street
# corner. About 420 returns off a street tree, a parked van, a lamp post and
# the road surface. The left panel is the point cloud as recorded; the right
# panel is the same returns dropped into a voxel occupancy grid and rendered
# as an isosurface, which is how a scan gets turned into geometry.
#
# Features: set vgrid + explicit vxrange/vyrange/vzrange, vfill with a splat
# radius and per-point weight, splot ... with isosurface level, set pm3d
# depthorder + set style fill + set isosurface mixed, a companion 3D scatter
# coloured 'lc palette' by return intensity, matched set view and set xyplane,
# and a labelled colorbox.
#
# Two things worth knowing:
#  * 'fc' AND 'lc' are both IGNORED on an isosurface, and so is the palette.
#    The surface is painted with the LINETYPE of its plot element, so the only
#    way to colour it is 'lt <n>' plus a 'set linetype <n> lc rgb ...'.
#    Reaching for 'fc' the usual way silently leaves it gnuplot's default
#    dark violet. The fill style (solid / transparent) IS honoured.
#  * vfill prints a four-line diagnostic (radius / brick / points / voxels
#    modified) to stdout. That is build noise, not a failure.

set angles degrees
seed = rand(2077)

# ---- the scan --------------------------------------------------------------
# columns: x, y, z (metres, scanner-local), return intensity 0..1
set print $ret

# street tree: a flattened ellipsoidal canopy on a short trunk
do for [i=1:180] {
    r  = 2.3*rand(0)**0.34
    th = 360.0*rand(0)
    ph = 180.0*rand(0)
    x = 4.0 + r*sin(ph)*cos(th)
    y = 8.0 + r*sin(ph)*sin(th)
    z = 5.4 + 1.45*r*cos(ph)
    if (z > 3.4) { print sprintf("%.3f %.3f %.3f %.3f", x, y, z, 0.14 + 0.20*rand(0)) }
}
do for [i=1:14] {
    print sprintf("%.3f %.3f %.3f %.3f", 4.0 + 0.14*invnorm(rand(0)), \
                  8.0 + 0.14*invnorm(rand(0)), 0.2 + 3.1*rand(0), 0.30 + 0.10*rand(0))
}

# parked van: returns only off the faces the scanner can see
do for [i=1:62] {   # roof
    print sprintf("%.3f %.3f %.3f %.3f", 7.0 + 4.5*rand(0), 1.5 + 2.7*rand(0), \
                  2.48 + 0.04*rand(0), 0.62 + 0.30*rand(0))
}
do for [i=1:56] {   # near side
    print sprintf("%.3f %.3f %.3f %.3f", 7.0 + 4.5*rand(0), 4.18 + 0.04*rand(0), \
                  0.10 + 2.4*rand(0), 0.62 + 0.30*rand(0))
}
do for [i=1:30] {   # front
    print sprintf("%.3f %.3f %.3f %.3f", 6.98 + 0.04*rand(0), 1.5 + 2.7*rand(0), \
                  0.10 + 2.4*rand(0), 0.62 + 0.30*rand(0))
}

# lamp post and its head
do for [i=1:48] {
    a = 360.0*rand(0)
    print sprintf("%.3f %.3f %.3f %.3f", 2.2 + 0.10*cos(a), 3.4 + 0.10*sin(a), \
                  0.1 + 6.3*rand(0), 0.40 + 0.14*rand(0))
}
do for [i=1:16] {
    a = 360.0*rand(0)
    print sprintf("%.3f %.3f %.3f %.3f", 2.2 + 0.34*cos(a), 3.4 + 0.34*sin(a), \
                  6.45 + 0.18*rand(0), 0.50 + 0.16*rand(0))
}

# road surface: sparse, and deliberately too sparse to build an isosurface
do for [i=1:56] {
    print sprintf("%.3f %.3f %.3f %.3f", 12.0*rand(0), 12.0*rand(0), \
                  0.02 + 0.05*rand(0), 0.22 + 0.22*rand(0))
}
set print

stats $ret using 3 nooutput
n_ret = STATS_records

# ---- occupancy grid --------------------------------------------------------
# The voxel ranges are NOT inherited from the plot; set them explicitly, and
# then set xrange/yrange/zrange to match or the two panels will not line up.
set vgrid $occ size 60
set vxrange [0:12]
set vyrange [0:12]
set vzrange [0:9]
vfill $ret using 1:2:3:(0.70):(1.0)

iso = 2.6                       # occupancy level that reads as "solid"

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 1180,620 transparent font ',11'
        set output 'out/12-lidar-voxel-isosurface.png'
    } else {
        set terminal svg size 1180,620 font 'sans,11'
        set output 'out/12-lidar-voxel-isosurface.svg'
    }

    set xrange [0:12]
    set yrange [0:12]
    set zrange [0:9]
    set cbrange [0:1]
    set xyplane at 0
    set view 62, 28, 1.22, 1.05
    set xlabel 'x (m)' offset 0,-0.5
    set ylabel 'y (m)' offset 0.5,-0.5
    set zlabel 'z (m)' rotate by 90 offset 1,0
    set xtics 0, 4
    set ytics 0, 4
    set ztics 0, 3
    set palette defined (0 '#1b3b6f', 0.35 '#2f8f7f', 0.6 '#d9b23a', 1 '#c0392b')
    set cblabel 'return intensity'
    set grid ztics lc rgb '#d8d8d8'
    set lmargin 8
    set rmargin 2
    unset key

    set multiplot

    # ---- left: the returns as recorded --------------------------------------
    set origin 0.0, 0.0
    set size 0.50, 1.0
    set title sprintf('(a) %d returns, coloured by intensity', n_ret) offset 0,-1.2
    set colorbox vertical user origin 0.075, 0.54 size 0.014, 0.30

    splot $ret using 1:2:3:4 with points pt 7 ps 0.45 lc palette notitle

    # ---- right: the same returns as an occupancy isosurface -----------------
    set origin 0.50, 0.0
    set size 0.50, 1.0
    set title sprintf('(b) 60^3 voxel grid, isosurface at level %.1f', iso) offset 0,-1.2
    unset colorbox
    set pm3d depthorder
    set style fill solid 1.0
    set isosurface mixed                # mixed triangles + quads
    set linetype 101 lc rgb '#5b8fc9'   # the ONLY way to colour the surface

    splot $occ with isosurface level iso lt 101 fs transparent solid 0.92 notitle

    unset pm3d
    unset multiplot
    set colorbox
    unset output
}
