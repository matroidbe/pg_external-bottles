#!/usr/bin/env bash
set -euo pipefail

# Build a pgx bottle of every third-party extension in bottles.tsv.
#
# Usage:
#   scripts/build.sh <out-dir> [<name>…]     # default: every row
#
# Each upstream is cloned at its pinned tag and bottled with `pgx bottle`
# against $PG_CONFIG (default: the one on PATH), with the row's build variables
# (pgx >= v0.2.0). Run it on the target platform:
# a bottle is keyed by (version, pg_major, os, arch).

OUT="${1:-}"
[[ -n "$OUT" ]] || { sed -n '4,7p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
shift
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PG_CONFIG="${PG_CONFIG:-$(command -v pg_config)}"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
BREW=$(brew --prefix)
# Without this, macOS stamps the dylibs with this host's macOS version and they
# refuse to load on any older one.
[[ "$(uname -s)" == Darwin ]] && export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-14.0}"

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
grep -v '^#' "$ROOT/bottles.tsv" | while IFS=$'\t' read -r name url tag vars subdir; do
    [[ $# -gt 0 && " $* " != *" $name "* ]] && continue
    echo "== $name $tag"
    if [[ "$url" == *.tar.gz || "$url" == *.tar.bz2 ]]; then
        # A release tarball (PostGIS ships configure and docs in it, not in
        # git), pinned by its sha256.
        tarball="$WORK/$(basename "$url")"
        curl -fsSL -o "$tarball" "$url"
        echo "$tag  $tarball" | shasum -a 256 -c - >/dev/null \
            || { echo "error: $(basename "$url") does not match its pinned sha256" >&2; exit 1; }
        mkdir -p "$WORK/$name.src" && tar xf "$tarball" -C "$WORK/$name.src"
        mv "$WORK/$name.src"/* "$WORK/$name"
        # A GPL bottle ships the exact source it was built from beside it.
        if grep -qs "GNU GENERAL PUBLIC LICENSE" "$ROOT/licenses/$name/COPYING"; then
            cp "$tarball" "$OUT/"
        fi
    else
        git -c advice.detachedHead=false clone -q --depth 1 --branch "$tag" "$url" "$WORK/$name"
    fi
    # Upstream declares no server configuration; ours travels in the bottle,
    # so `pgx install --configure` preloads and configures the extension.
    # The project can be a directory of the upstream tree (PL/Python lives in
    # PostgreSQL's src/pl/plpython), and overlays/<name>/ replaces files in it
    # (a PGXS Makefile for a module upstream only builds in-tree).
    project="$WORK/$name${subdir:+/$subdir}"
    [[ -d "$ROOT/overlays/$name" ]] && cp -R "$ROOT/overlays/$name/." "$project/"
    [[ -f "$ROOT/manifests/$name.pgbrew.toml" ]] && cp "$ROOT/manifests/$name.pgbrew.toml" "$project/pgbrew.toml"
    # Each variable reaches the build system as a make command-line variable
    # (PGXS) or a -D cache entry (CMake), which overrides the build files.
    # @BREW@ is the Homebrew prefix; a darwin: or linux: variable is this
    # platform's only.
    args=()
    IFS=';' read -ra kv <<< "$vars"
    for v in "${kv[@]}"; do
        case "$v" in
            "$OS":*) v="${v#"$OS":}" ;;
            darwin:*|linux:*) continue ;;
        esac
        [[ -n "$v" ]] && args+=(--build-var "${v//@BREW@/$BREW}")
    done
    pgx bottle "$project" -o "$OUT" ${args[@]+"${args[@]}"} </dev/null
done
# Each upstream's license (and NOTICE, which Apache-2.0 requires passing on)
# ships beside its bottle in every release.
for d in "$ROOT"/licenses/*/; do
    ext=$(basename "$d")
    for f in "$d"*; do cp "$f" "$OUT/$ext-$(basename "$f")"; done
done
cp "$ROOT/NOTICE" "$OUT/NOTICE"
(cd "$OUT" && shasum -a 256 ./*.tar.gz | sed 's| \./| |' > SHA256SUMS && cat SHA256SUMS)
