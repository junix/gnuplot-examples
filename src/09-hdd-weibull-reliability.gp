# 09 — Weibull probability plot: when do two 12 TB drive models wear out?
#
# Subject: power-on hours at failure for two 12 TB nearline models pulled from
# the same storage pods. Complete data, no suspensions: 18 failures of model
# HD-12A and 16 of HD-12B. The question the plot answers is whether either
# model gets through the 5-year warranty.
#
# Features: median ranks computed with set table / plot ... with table /
# unset table (Bernard's approximation, ($0+1-0.3)/(n+0.4), where $0 is the
# ZERO-based row index and restarts per curve when 'every' selects a block);
# the Weibull probability grid built with set nonlinear y; per-model fits in
# the linearised coordinates with errorvariables; plot for over a word() list;
# named ytics in failure percent; an arrow at the 63.2 % characteristic life;
# and a shaded warranty window.
#
# ORDERING MATTERS: 'set logscale x', 'set xrange' and 'set yrange' must all
# be issued BEFORE 'set nonlinear y via ...'. Doing it the other way round
# prints 'could not confirm linked axis inverse mapping function' no matter
# how carefully the range is chosen.

# ---- failure table (power-on hours, sorted per model) ----------------------
nA = 18
nB = 16
$raw << EOD
13276 1
21834 1
30286 1
34356 1
41074 1
44392 1
44855 1
45992 1
46799 1
51468 1
56218 1
65759 1
66513 1
69528 1
84811 1
85294 1
88291 1
90947 1
17156 2
17817 2
20397 2
22125 2
26868 2
27290 2
27838 2
31073 2
32178 2
35056 2
37593 2
38895 2
39371 2
40617 2
40911 2
45420 2
EOD

# ---- Bernard median ranks --------------------------------------------------
# 'with table' writes the using columns instead of drawing; each 'every'
# block is a separate curve, so $0 counts 0..n-1 within each model.
set table $mr
plot $raw every ::0::nA-1        using 1:(($0 + 0.7)/(nA + 0.4)):(1) with table, \
     $raw every ::nA::nA+nB-1    using 1:(($0 + 0.7)/(nB + 0.4)):(2) with table
unset table

# ---- rank regression in the linearised coordinates -------------------------
# ln(-ln(1-F)) = beta ln(t) - beta ln(eta): a straight line on this grid.
lin(u) = m*u + c
array BETA[2]
array BETAE[2]
array ETA[2]
array NN[2] = [nA, nB]

set fit quiet errorvariables logfile '/dev/null'
do for [i=1:2] {
    m = 2.0
    c = -20.0
    fit lin(x) $mr using ($3 == i ? log($1) : NaN):(log(-log(1.0 - $2))) via m, c
    BETA[i]  = m
    BETAE[i] = m_err
    ETA[i]   = exp(-c/m)
}
Ffit(i, t) = 1.0 - exp(-(t/ETA[i])**BETA[i])

mdl  = "HD-12A HD-12B"
cols = "#1f4e79 #d1603d"
warranty = 43800.0                       # 5 years of power-on hours

do for [fmt in "png svg"] {
    if (fmt eq "png") {
        set terminal pngcairo size 980,720 transparent font ',11'
        set output 'out/09-hdd-weibull-reliability.png'
    } else {
        set terminal svg size 980,720 font 'sans,11'
        set output 'out/09-hdd-weibull-reliability.svg'
    }

    set title 'Weibull probability plot: 12 TB nearline drives, complete failure data'
    set xlabel 'power-on hours at failure'
    set ylabel 'cumulative failures'

    # ranges first, transform second
    set logscale x
    set xrange [9000:200000]
    set yrange [0.005:0.995]
    set nonlinear y via log(-log(1-y)) inverse 1-exp(-exp(y))

    set xtics ('10 k' 10000, '20 k' 20000, '50 k' 50000, \
               '100 k' 100000, '200 k' 200000)
    set mxtics 10
    # tic label text is run through the tic FORMAT machinery, so a literal
    # per-cent sign has to be escaped as %%
    set ytics ('1 %%' 0.01, '2 %%' 0.02, '5 %%' 0.05, '10 %%' 0.10, '20 %%' 0.20, \
               '40 %%' 0.40, '63.2 %%' 0.632, '80 %%' 0.80, '90 %%' 0.90, '99 %%' 0.99)
    set grid xtics ytics mxtics lc rgb '#c8c8c8', lc rgb '#e8e8e8'
    set key bottom right box opaque samplen 2 spacing 1.25

    set object 1 rect from graph 0, graph 0 to first warranty, graph 1 behind \
        fc rgb '#e6efd4' fs solid 0.8 noborder
    set label 1 "5-year warranty window" at 42000, 0.013 right front tc rgb '#4a6b28'

    set arrow 1 from graph 0, first 0.632 to graph 1, first 0.632 nohead \
        lw 2 dt 3 lc rgb '#666666' front
    set label 2 'F = 63.2 %: the characteristic life {/Symbol h}' \
        at 200000, 0.632 right offset -1,0.8 front tc rgb '#444444'

    do for [i=1:2] {
        set arrow 1+i from first ETA[i], first 0.005 to first ETA[i], first 0.632 \
            nohead lw 2 dt 2 lc rgb word(cols, i) front
        set label 2+i sprintf("%s\n{/Symbol b} = %.2f +/- %.2f\n{/Symbol h} = %.1f kh (%.1f yr)\nF at 5 yr = %.0f %%", \
                              word(mdl, i), BETA[i], BETAE[i], ETA[i]/1000.0, \
                              ETA[i]/8766.0, 100.0*Ffit(i, warranty)) \
            at graph 0.04, (i == 1 ? 0.90 : 0.62) left front tc rgb word(cols, i)
    }

    plot for [i=1:2] Ffit(i, x) with lines lw 2.5 lc rgb word(cols, i) \
             title sprintf('%s fit', word(mdl, i)), \
         for [i=1:2] $mr using 1:($3 == i ? $2 : NaN) with points \
             pt (i == 1 ? 7 : 5) ps 1.2 lc rgb word(cols, i) \
             title sprintf('%s, %d failures', word(mdl, i), NN[i])

    unset object 1
    do for [a=1:3] { unset arrow a }
    do for [l=1:4] { unset label l }
    unset output
}
