# 06 — antenna pattern: a 7-element 435 MHz Yagi, polar and rectangular.
#
# Subject: the E-plane pattern of a 7-element Yagi-Uda for the 70 cm amateur
# satellite band (element spacing 0.32 lambda, tapered element currents),
# beside the gain and VSWR sweep that decides its usable bandwidth.
#
# Features: set polar with set angles degrees, trange [0:360] and a high
# sample count; set rrange [-30:0] with named rtics relabelled in dB;
# set grid polar; the 'unset border / unset xtics / unset ytics / unset raxis'
# cleanup a polar plot needs (without it the pattern sits inside a Cartesian
# box); filledcurves above r=<const> for the main lobe; a NaN floor clamp so
# nothing below rmin wraps back through the origin; polar rays drawn with
# set arrow; and a companion x1y2 panel with a shaded set object rect.
#
# NOTE the full state reset between the two panels: unset polar, unset grid,
# set size noratio, set angles radians, set autoscale, set trange [*:*], and
# restoring border and tics. Polar state leaks into the next panel otherwise.

set angles degrees

nel = 7                                  # driven element + reflector + 5 directors
kd  = 360.0*0.32                         # element spacing, electrical degrees
alp = -1.20*kd                           # progressive phase shift (endfire)
wf(n) = n == 0 ? 1.0 : exp(-0.13*n)      # current taper along the boom
psi(t) = kd*cos(t) + alp
af(t) = sqrt((sum [n=0:nel-1] wf(n)*cos(n*psi(t)))**2 \
           + (sum [n=0:nel-1] wf(n)*sin(n*psi(t)))**2)

# half-wave dipole element factor in the E-plane: zero along the element axis,
# which is what puts the deep nulls at +/- 90 degrees.
ef(t) = cos(90.0*sin(t))/(abs(cos(t)) + 1e-7)
pat(t) = af(t)*ef(t)

patmax = 0.0
do for [i=0:1800] { th = i/5.0; if (pat(th) > patmax) { patmax = pat(th) } }

gmax_dbi = 13.8                          # measured boresight gain
gdb(t) = 20*log10(pat(t)/patmax)         # normalised pattern, dB below peak

# Floor clamp: the +/- 90 degree nulls go far below the rrange minimum, and an
# unclamped value there is plotted at a NEGATIVE radius, wrapping back through
# the origin into the opposite lobe. Clamping pins them to the rim of the
# innermost ring; 'NaN' instead would break the trace there.
rmin = -30.0
gclamp(t) = gdb(t) < rmin ? rmin : gdb(t)

# half-power beamwidth, found by walking out from boresight
hp = 0.0
do for [i=0:900] { th = i/5.0; if (hp == 0.0 && gdb(th) <= -3.0) { hp = th } }
fb = -gdb(180)                           # front-to-back ratio, dB

# main lobe only, for the filled wedge
lobe(t) = (t <= hp || t >= 360.0 - hp) ? gclamp(t) : NaN

# ---- feedpoint sweep -------------------------------------------------------
# gain rolls off away from design centre; VSWR is a shifted parabola.
gain(f)  = gmax_dbi - 0.052*(f - 435.0)**2
vswr(f)  = 1.08 + 0.055*(f - 434.6)**2
f_lo = 434.6 - sqrt((2.0 - 1.08)/0.055)  # edges of the 2:1 VSWR window
f_hi = 434.6 + sqrt((2.0 - 1.08)/0.055)

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 1100,580 transparent font ',11'
        set output 'out/06-yagi-radiation-pattern.png'
    } else {
        set terminal svg size 1100,580 font 'sans,11'
        set output 'out/06-yagi-radiation-pattern.svg'
    }

    set multiplot

    # ---- left panel: polar radiation pattern -------------------------------
    set polar
    set angles degrees
    set trange [0:360]
    set samples 1441
    set rrange [rmin:0]
    set rtics ('0 dB' 0, '-5' -5, '-10' -10, '-20' -20, '-30' -30) \
        font ',9' tc rgb '#555555'
    set grid polar 30 lc rgb '#c0c0c0' lw 1
    set theta top clockwise               # boresight up, like a compass rose
    unset border                          # otherwise the pattern sits in a box
    unset xtics
    unset ytics
    unset raxis                           # hide the radial axis line itself
    unset key
    set size ratio 1 0.52,1.0
    set origin 0.0, 0.0
    set title sprintf('E-plane pattern, %d elements at 435 MHz', nel) offset 0,-0.5

    set style fill transparent solid 0.30 noborder

    # +/- half-power rays. Polar 'set arrow' takes Cartesian graph coordinates,
    # and with rrange [-30:0] the plot radius of level r is (r - rmin).
    set arrow 1 from 0,0 to (0-rmin)*sin(hp), (0-rmin)*cos(hp) \
        nohead lw 2 dt 2 lc rgb '#e45756' front
    set arrow 2 from 0,0 to -(0-rmin)*sin(hp), (0-rmin)*cos(hp) \
        nohead lw 2 dt 2 lc rgb '#e45756' front
    set label 1 sprintf("HPBW %.0f{/Symbol \\260}\nF/B %.1f dB\n%.1f dBi", 2*hp, fb, gmax_dbi) \
        at graph 0.02, 0.90 left front tc rgb '#1f4e79'
    set label 2 'boresight' at 0, (0-rmin)*0.93 center front font ',9' tc rgb '#555555'

    plot lobe(t) with filledcurves above r=rmin lc rgb '#e45756' notitle, \
         gclamp(t) with lines lw 2.5 lc rgb '#1f4e79' notitle

    # ---- reset every piece of polar state before the Cartesian panel --------
    unset polar
    unset grid
    unset arrow 1
    unset arrow 2
    unset label 1
    unset label 2
    unset rtics
    set theta right counterclockwise
    set raxis
    set size noratio 0.48,1.0
    set angles radians
    set autoscale
    set trange [*:*]
    set border 31 lw 1
    set xtics
    set ytics

    # ---- right panel: gain and VSWR across the band ------------------------
    set origin 0.52, 0.0
    set title 'gain and feedpoint VSWR, 430 - 440 MHz' offset 0,-0.5
    set xrange [430:440]
    set yrange [8:15]
    set y2range [1:3]
    set xlabel 'frequency (MHz)'
    set ylabel 'forward gain (dBi)'
    set y2label 'VSWR'
    set xtics 430, 2, 440
    set ytics 8, 1 nomirror
    set y2tics 1, 0.5
    set mxtics 2
    set grid xtics ytics lc rgb '#d8d8d8'
    set key bottom center box opaque samplen 2

    set object 1 rect from f_lo, graph 0 to f_hi, graph 1 behind \
        fc rgb '#dceccd' fs solid 0.7 noborder
    set label 3 sprintf("VSWR < 2:1 over\n%.1f - %.1f MHz", f_lo, f_hi) \
        at 435.0, 10.6 center front tc rgb '#3f6b28'
    set arrow 3 from first 430, second 2 to first 440, second 2 \
        nohead lw 2 dt 3 lc rgb '#888888' front

    plot gain(x) with lines lw 3 lc rgb '#1f4e79' title 'gain (left axis)', \
         vswr(x) axes x1y2 with lines lw 3 dt 2 lc rgb '#e45756' title 'VSWR (right axis)'

    unset object 1
    unset label 3
    unset arrow 3
    unset multiplot
    unset output
}
