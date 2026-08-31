# 04 — accelerated calendar ageing of NMC 18650 cells, fitted and extrapolated.
#
# Subject: five cell groups held at 50 % SOC at 25/35/45/55/65 C for a year.
# Capacity fade rate (percent of nameplate per 1000 h) follows an Arrhenius
# law, so the whole point of the experiment is the fit and what it predicts at
# a service temperature nobody has time to measure.
#
# Features: fit ... using 1:2:3 yerrors via A, Ea with errorvariables and
# covariancevariables (run ONCE, before the format loop), with yerrorbars,
# log y, a boxed sprintf'd label reporting Ea +/- its error and FIT_WSSR/
# FIT_NDF, a filledcurves +/-1 sigma confidence band propagated through the
# full covariance matrix, a normalised-residual panel with impulses against
# set zeroaxis, an x2 axis labelled in degrees C, and an extrapolation arrow.

# ---- measured fade rates ---------------------------------------------------
# column 1: 1000/T  (1/K)   column 2: fade rate (%/1000 h)
# column 3: 1 sigma of the fade rate    column 4: cell temperature (C)
$fade << EOD
3.3540  0.412  0.035  25
3.2452  0.795  0.055  35
3.1432  1.681  0.098  45
3.0474  2.934  0.185  55
2.9573  5.716  0.352  65
EOD

# Arrhenius rate with Ea in kJ/mol and u = 1000/T: k = A exp(-Ea u / R)
R = 8.31446                     # J / mol / K
k(u) = A*exp(-Ea*u/R)

A  = 1.0e9                      # starting guesses
Ea = 50.0

# 'quiet' keeps the iteration log off stderr; logfile /dev/null keeps a
# fit.log out of the working tree.
set fit quiet errorvariables covariancevariables logfile '/dev/null'
fit k(x) $fade using 1:2:3 yerrors via A, Ea

# 1 sigma band on the fitted curve, propagated with the full 2x2 covariance:
#   var(k) = (dk/dA)^2 sA^2 + (dk/dEa)^2 sEa^2 + 2 (dk/dA)(dk/dEa) cov(A,Ea)
dkdA(u)  = k(u)/A
dkdEa(u) = -k(u)*u/R
sk(u) = sqrt(dkdA(u)**2*A_err**2 + dkdEa(u)**2*Ea_err**2 \
             + 2.0*dkdA(u)*dkdEa(u)*FIT_COV_A_Ea)

u_of_C(tc) = 1000.0/(tc + 273.15)
u_svc = u_of_C(15)              # service temperature, outside the measured set
k_svc = k(u_svc)
yrs80 = 20.0/k_svc*1000.0/8766.0   # hours to 20 % fade, in years

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 960,780 transparent font ',11'
        set output 'out/04-cell-fade-arrhenius.png'
    } else {
        set terminal svg size 960,780 font 'sans,11'
        set output 'out/04-cell-fade-arrhenius.svg'
    }

    set lmargin 12
    set rmargin 4
    set multiplot

    # ---- upper panel: the Arrhenius fit ------------------------------------
    set origin 0.0, 0.30
    set size 1.0, 0.70
    set title 'NMC 18650 calendar ageing, 50 % SOC: capacity fade vs temperature'
    set xrange [2.92:3.53]
    set yrange [0.12:9.0]
    set logscale y
    set ylabel 'fade rate (% of nameplate per 1000 h)'
    unset xlabel
    set format x ''
    set ytics (0.2, 0.5, 1, 2, 5)
    set mytics 10
    set grid xtics ytics mytics lc rgb '#d8d8d8'

    set x2range [2.92:3.53]
    set x2tics ('65 C' u_of_C(65), '55 C' u_of_C(55), '45 C' u_of_C(45), \
                '35 C' u_of_C(35), '25 C' u_of_C(25), '15 C' u_of_C(15))

    set key at graph 0.97, 0.97 right top box opaque samplen 2 spacing 1.15

    set label 1 sprintf("Ea = %.1f +/- %.1f kJ/mol\nA = %.2e h^{-1}\n{/Symbol c}^2 = WSSR/ndf = %.2f", \
                        Ea, Ea_err, A, FIT_WSSR/FIT_NDF) \
        at graph 0.03, 0.21 left front boxed tc rgb '#1f4e79'
    set style textbox 1 opaque fc rgb '#ffffff' border lc rgb '#1f4e79'

    set arrow 1 from u_of_C(25), k(u_of_C(25)) to u_svc, k_svc \
        head filled size screen 0.014,18 lw 2 lc rgb '#e45756' front
    set label 2 sprintf("extrapolated to 15 C service temperature:\n%.2f %%/1000 h, i.e. 80 %% capacity after %.0f years", \
                        k_svc, yrs80) \
        at graph 0.32, 0.16 left front tc rgb '#a02323'

    set style fill transparent solid 0.30 noborder

    plot '+' using 1:(k($1)-sk($1)):(k($1)+sk($1)) with filledcurves \
             lc rgb '#4c78a8' title '+/- 1 {/Symbol s} on the fit', \
         k(x) with lines lw 2.5 lc rgb '#1f4e79' title 'k = A exp(-Ea/RT)', \
         $fade using 1:2:3 with yerrorbars pt 7 ps 1.3 lw 2 lc rgb '#e45756' \
             title 'measured, 1 {/Symbol s}'

    # ---- lower panel: normalised residuals ----------------------------------
    unset label 1
    unset label 2
    unset arrow 1
    unset title
    unset x2tics
    unset logscale y
    set origin 0.0, 0.0
    set size 1.0, 0.30
    set format x '%.2f'
    set xlabel '1000 / T   (1/K)'
    set ylabel "residual / {/Symbol s}"
    set yrange [-2.6:2.6]
    set ytics -2, 1, 2
    unset mytics
    set zeroaxis lw 2 lc rgb '#666666'
    set grid xtics noytics lc rgb '#d8d8d8'
    set key off

    plot $fade using 1:(($2-k($1))/$3) with impulses lw 6 lc rgb '#4c78a8' notitle, \
         $fade using 1:(($2-k($1))/$3) with points pt 7 ps 1.1 lc rgb '#1f4e79' notitle

    unset zeroaxis
    unset multiplot
    unset output
}
