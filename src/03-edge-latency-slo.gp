# 03 — one day of a CDN edge tier against its latency SLO.
#
# Subject: 24 h of an edge tier fronting an origin API, sampled every 10 min.
# A bad canary (edge-router 4.7.1) rolls out at 14:00 and is rolled back at
# 15:20; the burn-down panel shows what it cost out of the day's error budget
# (99 % of requests under 70 ms).
#
# Features: 2-row multiplot with shared left/right margins, filledcurves
# between two data columns as a percentile band, 'axes x1y2' boxes with an
# EXPLICIT y2range, set xdata time / timefmt / format x, set object rect
# ... behind + set arrow ... heads front + set label for the deploy window,
# a dashed SLO threshold, and a cumulative error-budget burn-down.

# ---- synthetic edge telemetry ----------------------------------------------
np = 144                       # 24 h at 10 min resolution
seed = rand(4711)

array TT[np]                   # minutes past midnight
array P50[np]
array P99[np]
array RPS[np]
array SLOW[np]                 # fraction of requests slower than the SLO

slo_ms   = 70.0
slo_frac = 0.01                # 1 % of requests may exceed slo_ms

totreq = 0.0
do for [i=1:np] {
    tm = (i-1)*10.0
    hr = tm/60.0
    # two diurnal humps: a midday plateau and a heavier evening peak
    rps = 2600 + 1900*exp(-(hr-12.5)**2/18.0) + 5200*exp(-(hr-20.5)**2/20.0)
    rps = rps*(1.0 + 0.03*invnorm(rand(0)))
    load = rps/8200.0
    p50 = 19.0 + 9.0*load + 0.7*invnorm(rand(0))
    p99 = 42.0 + 26.0*load**1.6 + 2.0*invnorm(rand(0))
    # canary window: 14:00 -> 15:20, ramping in over the first 20 minutes
    if (hr >= 14.0 && hr < 15.34) {
        ramp = hr < 14.34 ? (hr - 14.0)/0.34 : 1.0
        p50 = p50 + 13.0*ramp
        p99 = p99 + 58.0*ramp
    }
    # lognormal implied by (median, 99th pct) gives the tail beyond the SLO
    sig = log(p99/p50)/2.3263
    TT[i] = tm; P50[i] = p50; P99[i] = p99; RPS[i] = rps
    SLOW[i] = 1.0 - norm(log(slo_ms/p50)/sig)
    totreq = totreq + rps*600.0
}

budget = slo_frac*totreq       # slow requests allowed across the whole day

set print $edge
cum = 0.0
do for [i=1:np] {
    cum = cum + SLOW[i]*RPS[i]*600.0
    print sprintf("%02d:%02d %.2f %.2f %.0f %.5f %.2f %.2f", \
                  int(TT[i])/60, int(TT[i])%60, P50[i], P99[i], RPS[i], \
                  SLOW[i], 100.0*(1.0 - cum/budget), 100.0*(1.0 - TT[i]/1430.0))
}
set print

stats $edge using 6 nooutput
budget_left = STATS_min

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 1000,760 transparent font ',11'
        set output 'out/03-edge-latency-slo.png'
    } else {
        set terminal svg size 1000,760 font 'sans,11'
        set output 'out/03-edge-latency-slo.svg'
    }

    set xdata time
    set timefmt '%H:%M'
    set format x '%H:%M'
    set xrange ['00:00':'23:50']
    set xtics '00:00', 7200, '23:50'      # every two hours
    set mxtics 2

    # shared margins keep the two panels' x axes pixel-aligned
    set lmargin 11
    set rmargin 12

    set multiplot

    # ---- upper panel: latency vs SLO ---------------------------------------
    set origin 0.0, 0.34
    set size 1.0, 0.66
    set title 'edge tier POP-AMS3: request latency and offered load, 24 h'
    set ylabel 'edge response time (ms)'
    set y2label 'requests / s'
    set yrange [0:220]
    set y2range [0:12000]                 # explicit: y2 does not autoscale here
    set ytics nomirror
    set y2tics 0, 3000
    set grid xtics ytics lc rgb '#d8d8d8'
    set key top left box opaque samplen 2 spacing 1.1
    unset xlabel
    set format x ''

    set object 1 rect from '14:00', graph 0 to '15:20', graph 1 behind \
        fc rgb '#f4cccc' fs solid 0.55 noborder
    set arrow 1 from '14:00', graph 0.93 to '15:20', graph 0.93 heads front \
        size screen 0.008,20 lw 2 lc rgb '#a02323'
    set label 1 'canary edge-router 4.7.1 (80 min, rolled back)' \
        at '15:30', graph 0.93 left front tc rgb '#a02323'

    set boxwidth 540 absolute
    set style fill transparent solid 0.45 noborder

    plot $edge using 1:4 axes x1y2 with boxes lc rgb '#b3c6d9' \
             title 'offered load (right axis)', \
         $edge using 1:2:3 with filledcurves lc rgb '#9ecae1' \
             title 'p50 - p99 band', \
         $edge using 1:3 with lines lw 2.5 lc rgb '#1f4e79' title 'p99', \
         $edge using 1:2 with lines lw 2.5 lc rgb '#4c9bd4' title 'p50', \
         slo_ms with lines lw 2 dt 2 lc rgb '#e45756' title 'SLO: p99 < 70 ms'

    # ---- lower panel: error-budget burn-down --------------------------------
    unset object 1
    unset arrow 1
    unset label 1
    unset title
    unset y2tics
    unset y2label
    set origin 0.0, 0.0
    set size 1.0, 0.34
    set format x '%H:%M'
    set xlabel 'time of day (UTC)'
    set ylabel 'error budget left (%)'
    set yrange [0:105]
    set ytics 0, 25
    set key bottom left box opaque samplen 2

    set object 2 rect from '14:00', graph 0 to '15:20', graph 1 behind \
        fc rgb '#f4cccc' fs solid 0.55 noborder
    set label 2 sprintf('%.0f %% of the budget still unspent at 23:50', budget_left) \
        at '16:10', graph 0.62 left front tc rgb '#333333'

    plot $edge using 1:6 with filledcurves x1 fc rgb '#9ecae1' \
             fs transparent solid 0.5 noborder title 'budget remaining', \
         $edge using 1:6 with lines lw 2.5 lc rgb '#1f4e79' notitle, \
         $edge using 1:7 with lines lw 2 dt 3 lc rgb '#888888' \
             title 'even burn (reference)'

    unset object 2
    unset label 2
    unset multiplot
    unset output
}
