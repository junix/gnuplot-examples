set shell := ["bash", "-euo", "pipefail", "-c"]

# Animation frame count `just test` renders and requires; keep in step with
# the default in src/11-fiber-dispersion-frames.gp. Override: ANIM_NFRAMES=8 just test
anim_nframes := env_var_or_default("ANIM_NFRAMES", "36")

default: build

# Render every example into ./out (transparent PNG + SVG per script).
build:
    #!/usr/bin/env bash
    mkdir -p out
    for f in src/*.gp; do
        echo "=== $f"
        gnuplot "$f"
    done

# Verify DIR holds the complete animation frame sequence frame-000..frame-(N-1)
# as usable PNGs — every expected frame present, no extras (usage:
# just anim-verify DIR [N], N defaults to the 36-frame default of example 11).
anim-verify dir nframes="36":
    #!/usr/bin/env bash
    fail=0
    nframes={{nframes}}
    if ! [[ "$nframes" =~ ^[0-9]+$ ]] || (( nframes < 2 )); then
        echo "anim-verify: frame count must be an integer >= 2, got '$nframes'"
        exit 1
    fi
    if [[ ! -d "{{dir}}" ]]; then
        echo "anim-verify: no such directory {{dir}}"
        exit 1
    fi
    for ((i = 0; i < nframes; i++)); do
        frame="$(printf 'frame-%03d.png' "$i")"
        path="{{dir}}/$frame"
        if [[ ! -f "$path" ]]; then
            echo "missing animation frame $frame"
            fail=1
            continue
        fi
        sig="$(head -c 8 "$path" | od -An -tx1 | tr -d ' \n')"
        size="$(wc -c < "$path" | tr -d '[:space:]')"
        if [[ "$sig" != "89504e470d0a1a0a" ]] || (( size < 4096 )); then
            echo "animation frame $frame is not a usable PNG"
            fail=1
        fi
    done
    shopt -s nullglob
    found=( "{{dir}}"/frame-*.png )
    shopt -u nullglob
    if (( ${#found[@]} != nframes )); then
        echo "expected exactly $nframes animation frames, found ${#found[@]}"
        fail=1
    fi
    if (( fail )); then exit 1; fi
    echo "animation frames 000..$((nframes - 1)) verified in {{dir}}"

# Render the animation into a clean scratch directory — so stale frames under
# out/ cannot mask an interrupted render — and verify the full frame sequence.
anim-test:
    #!/usr/bin/env bash
    anim="$(mktemp -d)"
    trap 'rm -rf "$anim"' EXIT
    mkdir -p "$anim/out"
    if ! (cd "$anim" && gnuplot -e "nframes={{anim_nframes}}" "{{justfile_directory()}}/src/11-fiber-dispersion-frames.gp"); then
        echo "animation render failed"
        exit 1
    fi
    "{{just_executable()}}" anim-verify "$anim/out" "{{anim_nframes}}"

# Verify every script produced its expected outputs.
test: build anim-test
    #!/usr/bin/env bash
    fail=0
    for f in src/[0-9][0-9]-*.gp; do
        stem="$(basename "$f" .gp)"
        if [[ "$stem" == 11-* ]]; then
            continue    # animation frames: verified by anim-test
        fi
        for ext in png svg; do
            [[ -f "out/$stem.$ext" ]] || { echo "missing out/$stem.$ext"; fail=1; }
        done
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
clean: clean-artifacts

# Remove untracked intermediates. Preview: CLEAN_DRY_RUN=1 just clean-artifacts.
clean-artifacts:
    #!/usr/bin/env python3
    import fnmatch
    import glob
    import os
    from pathlib import Path
    import shutil
    import subprocess

    root = Path(r"""{{justfile_directory()}}""")
    os.chdir(root)
    dry_run = os.environ.get("CLEAN_DRY_RUN") == "1"
    if not (root / ".git").exists():
        print("No Git checkout at project root; preserving files.")
        raise SystemExit(0)
    # Fail closed if Git cannot identify protected files, including in worktrees.
    tracked = set(os.fsdecode(p) for p in subprocess.check_output(
        ["git", "ls-files", "-z"]).split(b"\0") if p)
    protected = set(tracked)
    for name in tracked:
        protected.update(str(p) for p in Path(name).parents)
    def remove(path):
        name = path.as_posix()
        if name in protected or path.is_symlink():
            return
        if path.is_dir():
            for directory, children, files in os.walk(path, followlinks=False):
                if (Path(directory) / ".git").exists():
                    return
                if any(Path(n).suffix in {".tex", ".typ", ".blend", ".ipynb"} for n in files):
                    return
                children[:] = [n for n in children if not (Path(directory) / n).is_symlink()]
        print(("Would remove " if dry_run else "Removing ") + name)
        if not dry_run:
            shutil.rmtree(path) if path.is_dir() else path.unlink()

    # Project-specific build outputs. Keep dependencies, models and final media.
    build_dirs = ["out"]
    for pattern in build_dirs:
        if Path(pattern).is_absolute() or ".." in Path(pattern).parts or pattern in {"", "."}:
            raise SystemExit("Build cleanup paths must stay within the project")
        for name in glob.glob(pattern):
            path = Path(name)
            if path.exists() and not any(p.is_symlink() for p in [path, *path.parents]):
                remove(path)

    caches = {"__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache"}
    skip = {".git", ".hg", ".svn", "legacy", "node_modules", ".venv", "venv", "vendor", "third_party", "target", ".build", ".lake", "dist-newstyle", ".stack-work"}
    tex = ("*.aux", "*.fls", "*.fdb_latexmk", "*.synctex.gz", "*.nav", "*.snm", "*.vrb", "*.bcf", "*.run.xml", "*.toc", "*.lof", "*.lot")
    images = {".png", ".jpg", ".jpeg", ".webp"}
    def walk_error(error):
        raise error
    for current, dirs, files in os.walk(".", onerror=walk_error, followlinks=False):
        base = Path(current)
        for name in dirs[:]:
            path = base / name
            if path.is_symlink() or name in skip or (path / ".git").exists():
                dirs.remove(name)
            elif name in caches or name.endswith(".egg-info"):
                remove(path)
                dirs.remove(name)
            elif name in {".cache", ".render-cache"} and "docs" in path.parts:
                ignored = subprocess.run(["git", "check-ignore", "-q", "--", str(path)])
                if ignored.returncode not in (0, 1):
                    raise SystemExit(ignored.returncode)
                if ignored.returncode == 0:
                    remove(path)
                    dirs.remove(name)
        for name in files:
            path = base / name
            if path.as_posix() in tracked or path.is_symlink():
                continue
            is_tex = any(fnmatch.fnmatchcase(name, pattern) for pattern in tex)
            is_tex_log = path.suffix == ".log" and path.with_suffix(".tex").is_file()
            parts = path.parts
            in_docs = any(p in {"docs", "doc", "infographics"} or p.endswith("-explainer") for p in parts[:-1])
            inspection = name.endswith(".lint.png") or name.startswith("slice-") or any(p in {"crops", "inspect", "slices", "tiles", "sections"} for p in parts[:-1])
            # Only ignored inspection images qualify; finished render/evidence trees stay.
            is_image = in_docs and inspection and path.suffix.lower() in images
            if is_image:
                result = subprocess.run(["git", "check-ignore", "-q", "--", str(path)])
                if result.returncode not in (0, 1):
                    raise SystemExit(result.returncode)
                is_image = result.returncode == 0
            if is_tex or is_tex_log or is_image:
                remove(path)
