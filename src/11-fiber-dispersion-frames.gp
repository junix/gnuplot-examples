# 11 — ANIMATION: a pulse dispersing along 80 km of SMF-28.
#
# Subject: a transform-limited Gaussian pulse (40 ps FWHM, 1550 nm) launched
# into standard single-mode fibre. Group velocity dispersion (beta2 =
# -21.7 ps^2/km) broadens it and paints a linear frequency chirp across it.
# One frame per distance step; feed them to ffmpeg with 'just gif'.
#
# PNG only: these frames exist to be assembled into an animation, and an SVG
# per frame would be dead weight.
#
# Usage: gnuplot src/11-fiber-dispersion-frames.gp
#        gnuplot -e "nframes=60" -e "zmax=120" src/11-fiber-dispersion-frames.gp
#
# Features: complex field with the {0,1} literal and abs()**2 for intensity,
# a do for frame loop with sprintf'd output paths and per-frame titles, a
# per-frame multiplot, set table sampling the '+' pseudofile followed by
# NUMERICAL differentiation of the phase for the chirp trace, a datablock
# accumulated across frames with 'set print ... append', ranges frozen for
# every frame so the animation does not breathe, and exists() guards so the
# two knobs can be overridden from the command line.
#
# The launch pulse is 40 ps rather than the few-picosecond pulse of a real
# 100G link on purpose: at 5 ps, 80 km of SMF broadens the pulse by a factor
# of ~190 and nothing survives inside a frozen time window.

nframes = exists("nframes") ? nframes : 36      # >= 30: 'just test' looks for frame-029
zmax    = exists("zmax")    ? zmax    : 80.0    # km

jj    = {0,1}
fwhm0 = 40.0                     # launch FWHM, ps
T0    = fwhm0/(2.0*sqrt(log(2))) # 1/e half-width of the field, ps
b2    = -21.7                    # GVD at 1550 nm, ps^2/km
LD    = T0**2/abs(b2)            # dispersion length, km
Twin  = 180.0                    # half time window, ps
nsamp = 401

# Analytic Gaussian propagation (Agrawal 3.2.7):
#   Q(z) = T0^2 - i b2 z,  A(z,T) = T0/sqrt(Q) exp(-T^2/(2Q))
Q(z)    = T0**2 - jj*b2*z
A(z, T) = T0/sqrt(Q(z)) * exp(-T**2/(2.0*Q(z)))
I(z, T) = abs(A(z, T))**2        # intensity, normalised to the launch peak

# The T-dependent part of arg(A), written out analytically so that it never
# wraps: differentiating a wrapped phase numerically gives spikes at every
# 2 pi jump. This is the same discipline as the Bode phase in example 10.
phi(z, T) = -b2*z*T**2/(2.0*abs(Q(z))**2)

bro(z)  = sqrt(1.0 + (z/LD)**2)  # broadening factor
dT      = 2.0*Twin/(nsamp - 1)

# stateful numerical derivative: the classic gnuplot idiom
prev = NaN
dd(y) = (v = y - prev, prev = y, v/dT)

set samples nsamp
undefine $prog

do for [i=0:nframes-1] {
    z  = zmax*i/(nframes - 1.0)
    br = bro(z)

    # ---- chirp: tabulate the phase, then differentiate it numerically ------
    set xrange [-Twin:Twin]
    set yrange [-1:1]           # 'with table' ignores it, but at z = 0 every
                                # tabulated value is 0 and autoscale complains
    set table $phase
    plot '+' using 1:(phi(z, $1))
    unset table

    prev = NaN
    set table $chirp
    plot $phase using ($1 - dT/2.0):(-dd($2)*1000.0/(2.0*pi))
    unset table

    # ---- accumulating record of how wide the pulse has become --------------
    if (i == 0) { set print $prog } else { set print $prog append }
    print sprintf("%.4f %.3f %.5f", z, fwhm0*br, 1.0/br)
    set print

    set terminal pngcairo size 760,660 transparent font ',11'
    set output sprintf('out/frame-%03d.png', i)

    set lmargin 11
    set rmargin 4
    set multiplot

    # ---- envelope ----------------------------------------------------------
    set origin 0.0, 0.62
    set size 1.0, 0.38
    set title sprintf('40 ps pulse in SMF-28 at z = %5.1f km   (FWHM %5.1f ps, peak %.2f of launch)', \
                      z, fwhm0*br, 1.0/br) offset 0,-0.5
    set xrange [-Twin:Twin]
    set yrange [0:1.08]
    set ytics 0, 0.25
    set ylabel 'P(T) / P(0,0)'
    set format x ''
    unset xlabel
    set grid xtics ytics lc rgb '#d8d8d8'
    set key top right box opaque samplen 2
    set style fill transparent solid 0.35 noborder

    plot '+' using 1:(I(z, $1)) with filledcurves x1 lc rgb '#4c78a8' \
             title sprintf('z = %.1f km', z), \
         '+' using 1:(I(z, $1)) with lines lw 2.5 lc rgb '#1f4e79' notitle, \
         '+' using 1:(I(0.0, $1)) with lines lw 2 dt 2 lc rgb '#888888' \
             title 'launch pulse'

    # ---- chirp --------------------------------------------------------------
    unset title
    set origin 0.0, 0.32
    set size 1.0, 0.30
    set yrange [-20:20]
    set ytics -15, 5
    set ylabel 'chirp (GHz)'
    set format x '%g'
    set xlabel 'time in the retarded frame, T (ps)'
    set key top right box opaque samplen 2
    set zeroaxis lw 1.5 lc rgb '#aaaaaa'

    # the chirp is only meaningful where there is light: blank it elsewhere
    plot $chirp using 1:(I(z, $1) > 2e-3 ? $2 : NaN) with lines lw 2.5 \
             lc rgb '#e45756' title 'instantaneous frequency (numerical d{/Symbol f}/dT)'

    # ---- accumulating broadening trace --------------------------------------
    set origin 0.0, 0.0
    set size 1.0, 0.32
    unset zeroaxis
    set xrange [0:zmax]
    set yrange [0:fwhm0*bro(zmax)*1.12]
    set format x '%g'
    set xlabel 'distance along the fibre (km)'
    set ylabel 'FWHM (ps)'
    set ytics 0, 40
    set key off

    set arrow 1 from z, graph 0 to z, graph 1 nohead lw 1.5 dt 3 lc rgb '#888888'
    set label 1 sprintf('L_D = %.1f km', LD) at zmax*0.02, fwhm0*bro(zmax)*1.02 left

    plot $prog using 1:2 with filledcurves x1 lc rgb '#9ecae1' \
             fs transparent solid 0.4 noborder notitle, \
         $prog using 1:2 with lines lw 2.5 lc rgb '#1f4e79' notitle, \
         $prog using 1:2 every ::|$prog|-1 with points pt 7 ps 1.4 \
             lc rgb '#e45756' notitle

    unset arrow 1
    unset label 1
    unset multiplot
    unset output
}
