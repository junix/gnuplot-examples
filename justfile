set shell := ["bash", "-euo", "pipefail", "-c"]

default: build

# Render every example into ./out (transparent PNG + SVG per script).
build:
    #!/usr/bin/env bash
    mkdir -p out
    for f in src/*.gp; do
        echo "=== $f"
        gnuplot "$f"
    done

# Verify every script produced its expected outputs.
test: build
    #!/usr/bin/env bash
    fail=0
    for f in src/[0-9][0-9]-*.gp; do
        stem="$(basename "$f" .gp)"
        if [[ "$stem" == 12-* ]]; then
            [[ -f out/frame-029.png ]] || { echo "missing animation frames"; fail=1; }
        else
            for ext in png svg; do
                [[ -f "out/$stem.$ext" ]] || { echo "missing out/$stem.$ext"; fail=1; }
            done
        fi
    done
    if (( fail )); then exit 1; fi
    echo "all outputs present"

# Demos repo — no binary, no launcher (ADR-749: nothing to install).
install:
    @echo "gnuplot-examples: demos repo, nothing to install"

# Combine the animation frames into a GIF (requires ffmpeg).
gif:
    ffmpeg -framerate 10 -i out/frame-%03d.png out/animation.gif

# Remove all generated images.
clean:
    rm -rf out
    mkdir -p out
    touch out/.gitkeep
