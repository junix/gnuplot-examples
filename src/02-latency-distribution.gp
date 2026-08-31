# 02 — the shape of a latency distribution.
#
# Subject: 6,000 requests logged in one hour against a document-search API.
# Two populations are mixed: cache hits land near 18 ms, origin misses near
# 120 ms, and the miss rate differs per route. Everything downstream of the
# generator is the analysis you would actually run on such a log.
#
# Features: datablock generation with 'set print $req' + rand()/invnorm(),
# stats ... nooutput -> STATS_records/mean/median, smooth frequency into
# log-spaced bins with a bin() function + set boxwidth, smooth cumulative on
# x1y2 as the empirical CDF (y2range MUST be set explicitly), smooth kdensity,
# set arrow / set label for percentile markers, and a lower multiplot panel of
# per-route boxplots using the full using (x):(value):(width):(factor) form
# with set style boxplot outliers and set jitter.

# ---- synthetic access log --------------------------------------------------
# Built ONCE, before the format loop: rand() advances its internal state, so
# regenerating inside the loop would make the SVG show different data from the
# PNG. ('set print $req' overwrites the datablock, it does not append.)
nreq  = 6000
seed  = rand(20240831)          # rand(<non-zero>) seeds the generator

# Routes are listed in alphabetical order so that the numeric index in column 3
# matches the position 'set style boxplot ... sorted' gives each factor below.
array rname[4] = ["/doc-fetch", "/facets", "/search", "/suggest"]
array rshare[4] = [0.15, 0.30, 0.75, 1.00]   # cumulative traffic share
array rhit[4]  = [26.0, 21.0, 18.0, 11.0]    # median cache-hit latency, ms
array rmiss[4] = [190.0, 140.0, 120.0, 90.0] # median origin-miss latency, ms
array rpmiss[4] = [0.28, 0.15, 0.10, 0.04]   # miss rate

set print $req
do for [i=1:nreq] {
    u = rand(0)
    r = u < rshare[1] ? 1 : (u < rshare[2] ? 2 : (u < rshare[3] ? 3 : 4))
    if (rand(0) < rpmiss[r]) {
        t = rmiss[r]*exp(0.40*invnorm(rand(0)))
    } else {
        t = rhit[r]*exp(0.22*invnorm(rand(0)))
    }
    print sprintf("%.2f %s %d", t, rname[r], r)
}
set print

# ---- summary statistics ----------------------------------------------------
stats $req using 1 nooutput
n_obs  = STATS_records
mean_ms = STATS_mean
med_ms  = STATS_median

# Percentiles: gnuplot's stats gives quartiles only, so read the tail off the
# empirical CDF that 'smooth cumulative' builds (it sorts by x for us).
set table $cdf
plot $req using 1:(1.0/nreq) smooth cumulative
unset table

p50 = 0; p95 = 0; p99 = 0
do for [i=1:|$cdf|] {
    line = $cdf[i]
    if (strlen(line) > 0 && line[1:1] ne '#') {
        lx = real(word(line, 1)); ly = real(word(line, 2))
        if (p50 == 0 && ly >= 0.50) { p50 = lx }
        if (p95 == 0 && ly >= 0.95) { p95 = lx }
        if (p99 == 0 && ly >= 0.99) { p99 = lx }
    }
}

# ---- log-spaced binning ----------------------------------------------------
# The x axis of the upper panel IS log10(latency): binning, the kernel density
# and the CDF all live in that coordinate, so the bins are evenly spaced and
# the Gaussian kernel is Gaussian in log space (the right kernel for a
# multiplicative process). Only the tic labels are converted back to ms.
blo = 5.0; bhi = 500.0; nbins = 60
binw = (log10(bhi) - log10(blo))/nbins           # bin width in decades
bin(t) = log10(blo) + binw*(floor((log10(t) - log10(blo))/binw) + 0.5)

# Weighting every kdensity sample by binw turns the density (per decade) into
# the same "requests per bin" units the histogram boxes use.

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 1000,860 transparent font ',11'
        set output 'out/02-latency-distribution.png'
    } else {
        set terminal svg size 1000,860 font 'sans,11'
        set output 'out/02-latency-distribution.svg'
    }

    set multiplot

    # ---- upper panel: pooled distribution ----------------------------------
    set origin 0.0, 0.40
    set size 1.0, 0.60
    set lmargin 11
    set rmargin 11

    unset logscale y          # the lower panel leaves log y on across formats
    set title sprintf('document-search API, 1 h: %d requests, mean %.1f ms, median %.1f ms', \
                      n_obs, mean_ms, med_ms)
    set xrange [log10(blo):log10(bhi)]
    set xtics ('5' log10(5), '10' 1, '20' log10(20), '35' log10(35), '50' log10(50), \
               '100' 2, '200' log10(200), '350' log10(350), '500' log10(500))
    set xlabel 'request latency (ms, log scale)'
    set ylabel 'requests per bin'
    set y2label 'cumulative fraction'
    set yrange [0:700]
    set y2range [0:1]                 # without this y2 collapses onto the data
    set ytics nomirror
    set y2tics 0, 0.25
    set grid xtics ytics lc rgb '#d0d0d0'
    set key at graph 0.99, 0.42 right top box opaque samplen 2
    set boxwidth 0.88*binw absolute
    set style fill solid 0.55 noborder

    set arrow 1 from log10(p50), graph 0 to log10(p50), graph 0.80 nohead lw 2 dt 3 lc rgb '#54a24b'
    set arrow 2 from log10(p95), graph 0 to log10(p95), graph 0.66 nohead lw 2 dt 3 lc rgb '#f58518'
    set arrow 3 from log10(p99), graph 0 to log10(p99), graph 0.52 nohead lw 2 dt 3 lc rgb '#e45756'
    set label 1 sprintf('p50 = %.0f ms', p50) at log10(p50), graph 0.83 center tc rgb '#54a24b'
    set label 2 sprintf('p95 = %.0f ms', p95) at log10(p95), graph 0.69 center tc rgb '#f58518'
    set label 3 sprintf('p99 = %.0f ms', p99) at log10(p99), graph 0.55 right offset -0.5,0 tc rgb '#e45756'

    plot $req using (bin($1)):(1.0) smooth frequency with boxes \
             lc rgb '#9ecae1' title sprintf('%d log-spaced bins', nbins), \
         $req using (log10($1)):(binw) smooth kdensity bandwidth 0.022 with lines \
             lw 2.5 lc rgb '#1f4e79' title 'kernel density (bw 0.022 decade)', \
         $req using (log10($1)):(1.0/nreq) smooth cumulative axes x1y2 with lines \
             lw 2.5 lc rgb '#e45756' title 'empirical CDF (right axis)'

    # ---- lower panel: per-route boxplots ------------------------------------
    unset arrow
    unset label
    unset y2tics
    unset y2label
    unset title
    set origin 0.0, 0.0
    set size 1.0, 0.40

    # Ranges before 'set logscale', not after: the upper panel left yrange
    # at [0:*], and a zero lower bound is invalid on a log axis.
    set yrange [5:900]
    set logscale y
    set ytics (5, 10, 20, 50, 100, 200, 500)
    set xrange [0.4:4.6]
    set xtics auto
    set ylabel 'latency (ms, log scale)'
    set xlabel 'route (box = quartiles, whiskers = 1.5 IQR, dots = every 4th request)'
    set grid ytics noxtics lc rgb '#d0d0d0'
    set key off

    set style fill solid 0.45 border lc rgb '#333333'
    set style data boxplot
    set style boxplot outliers pointtype 6 range 1.5 separation 1 labels auto sorted
    set jitter overlap 0.03 spread 0.09 wrap 9

    plot $req every 4 using 3:1 with points pt 7 ps 0.35 lc rgb '#a8c8e0' notitle, \
         $req using (1.0):1:(0.5):(stringcolumn(2)) lc rgb '#4c78a8' notitle

    unset jitter
    unset multiplot
    unset output
}
