# Generate frames for an animation (run then combine with ffmpeg/gif tools)
# PNG only: frames are meant to be fed to ffmpeg; SVG frames aren't useful here.
# Usage: gnuplot -e "nframes=30" 12-animation-frames.gp
nframes = exists("nframes") ? nframes : 30
do for [i=0:nframes-1] {
    set terminal pngcairo size 600,400 transparent
    set output sprintf('out/frame-%03d.png', i)
    set title sprintf('Wave at t = %.2f', i/10.0)
    set xrange [-6:6]; set yrange [-1.5:1.5]
    set grid
    plot sin(x + i/10.0) w l lw 2 notitle
}
