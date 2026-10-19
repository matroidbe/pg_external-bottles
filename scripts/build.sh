#!/usr/bin/env bash
set -euo pipefail

# Build a pgx bottle of every third-party extension in bottles.tsv.
#
# Usage:
#   scripts/build.sh <out-dir> [<name>…]     # default: every row
#
# Each upstream is cloned at its pinned tag and bottled with `pgx bottle`
# against $PG_CONFIG (default: the one on PATH). Run it on the target platform:
# a bottle is keyed by (version, pg_major, os, arch).

OUT="${1:-}"
[[ -n "$OUT" ]] || { sed -n '4,7p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
shift
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PG_CONFIG="${PG_CONFIG:-$(command -v pg_config)}"
# Without this, macOS stamps the dylibs with this host's macOS version and they
# refuse to load on any older one.
[[ "$(uname -s)" == Darwin ]] && export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-14.0}"

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
grep -v '^#' "$ROOT/bottles.tsv" | while IFS=$'\t' read -r name url tag env; do
    [[ $# -gt 0 && " $* " != *" $name "* ]] && continue
    echo "== $name $tag"
    git -c advice.detachedHead=false clone -q --depth 1 --branch "$tag" "$url" "$WORK/$name"
    if [[ -n "$env" ]]; then
        env "${env%%=*}=${env#*=}" pgx bottle "$WORK/$name" -o "$OUT"
    else
        pgx bottle "$WORK/$name" -o "$OUT"
    fi
done
(cd "$OUT" && shasum -a 256 ./*.tar.gz | sed 's| \./| |' > SHA256SUMS && cat SHA256SUMS)
