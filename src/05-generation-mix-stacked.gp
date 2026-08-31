# 05 — the duck curve: 24 h of a grid's generation mix.
#
# Subject: one clear spring day on a CAISO-shaped system, 5-minute
# resolution. Solar hollows out the middle of the day and the gas fleet has to
# climb back out of the hole between 16:00 and 20:00 — the evening ramp that
# the whole "duck curve" argument is about.
#
# ONE dataset drives both panels: the 5-minute series for the stacked area,
# and its hourly means for the clustered histogram underneath.
#
# Features: set xdata time with hourly xtics, stacked filledcurves x1 built
# from cumulative column expressions and plotted TOP BAND FIRST, set style
# fill transparent solid noborder, net load on x1y2 dashed, set object rect +
# a two-headed set arrow labelled with a sprintf'd ramp rate, set key outside
# bottom center horizontal maxrows 2, and a clustered histogram panel
# (set style data histograms / set style histogram clustered) of the same day.

np = 288                        # 24 h at 5 min
seed = rand(90210)

array HRSUM[24*6]               # hourly totals per source, for the lower panel
do for [i=1:24*6] { HRSUM[i] = 0.0 }

netmin = 1e9; netmin_t = 0
netmax = -1e9; netmax_t = 0

set print $mix
do for [i=1:np] {
    tm = (i-1)*5.0
    hr = tm/60.0

    demand  = 22.0 + 5.8*exp(-(hr-19.6)**2/7.0) + 1.5*exp(-(hr-9.0)**2/5.0) \
                   - 2.3*exp(-(hr-4.0)**2/9.0) + 0.10*invnorm(rand(0))
    solar   = (hr > 6.3 && hr < 19.3) ? 11.0*sin(pi*(hr-6.3)/13.0)**1.35 : 0.0
    wind    = 1.9 + 1.1*sin(2*pi*(hr-3.0)/24.0) + 0.09*invnorm(rand(0))
    wind    = wind < 0.3 ? 0.3 : wind
    nuclear = 2.24                                    # two units, always on
    hydro   = 1.8 + 0.55*(demand - 22.0)
    hydro   = hydro < 1.2 ? 1.2 : hydro

    firm    = nuclear + hydro + wind + solar
    imports = 0.35*(demand - firm)
    imports = imports > 7.0 ? 7.0 : (imports < 0.5 ? 0.5 : imports)
    gas     = demand - firm - imports                 # gas is the balancing fleet

    net = demand - solar - wind                       # net load = what firm plant sees
    if (hr >= 11.0 && hr <= 18.0 && net < netmin) { netmin = net; netmin_t = tm }
    if (hr >= 16.0 && hr <= 23.0 && net > netmax) { netmax = net; netmax_t = tm }

    h = int(hr)
    HRSUM[h*6+1] = HRSUM[h*6+1] + nuclear/12.0
    HRSUM[h*6+2] = HRSUM[h*6+2] + hydro/12.0
    HRSUM[h*6+3] = HRSUM[h*6+3] + imports/12.0
    HRSUM[h*6+4] = HRSUM[h*6+4] + gas/12.0
    HRSUM[h*6+5] = HRSUM[h*6+5] + wind/12.0
    HRSUM[h*6+6] = HRSUM[h*6+6] + solar/12.0

    # cumulative columns: each band is drawn down to the x axis, top band first
    c1 = nuclear
    c2 = c1 + hydro
    c3 = c2 + imports
    c4 = c3 + gas
    c5 = c4 + wind
    c6 = c5 + solar
    print sprintf("%02d:%02d %.3f %.3f %.3f %.3f %.3f %.3f %.3f", \
                  int(tm)/60, int(tm)%60, c1, c2, c3, c4, c5, c6, net)
}
set print

ramp = (netmax - netmin)/((netmax_t - netmin_t)/60.0)*1000.0   # MW per hour

# hourly means at four representative hours, for the clustered histogram
set print $hourly
do for [h in "4 10 13 20"] {
    hh = h + 0
    print sprintf("%02d:00 %.3f %.3f %.3f %.3f %.3f %.3f", hh, \
                  HRSUM[hh*6+1], HRSUM[hh*6+2], HRSUM[hh*6+3], \
                  HRSUM[hh*6+4], HRSUM[hh*6+5], HRSUM[hh*6+6])
}
set print

c_nuc = '#7b6d8d'; c_hyd = '#4c9bd4'; c_imp = '#9aa0a6'
c_gas = '#d1603d'; c_wnd = '#6aa84f'; c_sol = '#f2c14e'

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 1020,820 transparent font ',11'
        set output 'out/05-generation-mix-stacked.png'
    } else {
        set terminal svg size 1020,820 font 'sans,11'
        set output 'out/05-generation-mix-stacked.svg'
    }

    set lmargin 11
    set rmargin 11
    set multiplot

    # ---- upper panel: stacked generation mix -------------------------------
    set origin 0.0, 0.34
    set size 1.0, 0.66
    set title 'generation mix and net load, clear spring weekday'
    set xdata time
    set timefmt '%H:%M'
    set format x '%H:%M'
    set xrange ['00:00':'23:55']
    set xtics '00:00', 10800, '23:55'
    set mxtics 3
    set yrange [0:32]
    set y2range [0:32]
    set ytics 0, 5 nomirror
    set y2tics 0, 5
    set ylabel 'generation (GW)'
    set y2label 'net load = demand - solar - wind (GW)'
    set grid xtics ytics lc rgb '#d0d0d0'
    set style fill transparent solid 0.85 noborder
    set key outside bottom center horizontal maxrows 2 samplen 2 width 1

    set object 1 rect from netmin_t*60.0, graph 0 to netmax_t*60.0, graph 1 \
        behind fc rgb '#e8e2f0' fs solid 0.55 noborder
    set arrow 1 from netmin_t*60.0, netmin to netmax_t*60.0, netmax heads front \
        size screen 0.010,18 lw 2.5 lc rgb '#5b3f8c'
    set label 1 sprintf('evening ramp: %.1f GW in %.1f h  (%.0f MW/min)', \
                        netmax - netmin, (netmax_t - netmin_t)/60.0, ramp/60.0) \
        at netmin_t*60.0 - 5400, netmax + 2.2 left front tc rgb '#5b3f8c'

    set label 2 "net load (right axis) is exactly the top of the\ndispatchable stack: everything below wind and solar" \
        at '00:30', 26.4 left front tc rgb '#222222'

    # top band first: each filledcurves x1 fills from its cumulative total
    # down to the axis, so later (lower) bands paint over the earlier ones.
    plot $mix using 1:7 with filledcurves x1 lc rgb c_sol title 'solar', \
         $mix using 1:6 with filledcurves x1 lc rgb c_wnd title 'wind', \
         $mix using 1:5 with filledcurves x1 lc rgb c_gas title 'natural gas', \
         $mix using 1:4 with filledcurves x1 lc rgb c_imp title 'imports', \
         $mix using 1:3 with filledcurves x1 lc rgb c_hyd title 'large hydro', \
         $mix using 1:2 with filledcurves x1 lc rgb c_nuc title 'nuclear', \
         $mix using 1:8 axes x1y2 with lines lw 3 dt 2 lc rgb '#222222' \
             title 'net load'

    # ---- lower panel: four hours, side by side ------------------------------
    unset object 1
    unset arrow 1
    unset label 1
    unset label 2
    unset title
    unset y2tics
    unset y2label
    unset xdata                       # histograms use category strings, not time
    set xrange [*:*]                  # the time xrange above would hide them
    set xtics auto
    unset mxtics
    set origin 0.0, 0.0
    set size 1.0, 0.34
    set format x '%s'
    set yrange [0:16]
    set ytics 0, 4
    set ylabel 'hourly mean (GW)'
    set xlabel 'hourly means at four hours of the same day (colours as above)'
    set grid ytics noxtics lc rgb '#d0d0d0'
    set key off
    set style data histograms
    set style histogram clustered gap 1
    set style fill solid 0.85 border lc rgb '#ffffff'
    set boxwidth 0.9 relative

    plot $hourly using 2:xtic(1) lc rgb c_nuc title 'nuclear', \
         '' using 3 lc rgb c_hyd title 'large hydro', \
         '' using 4 lc rgb c_imp title 'imports', \
         '' using 5 lc rgb c_gas title 'natural gas', \
         '' using 6 lc rgb c_wnd title 'wind', \
         '' using 7 lc rgb c_sol title 'solar'

    unset multiplot
    unset output
}
