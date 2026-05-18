#!/usr/bin/env bash
# build.sh — native build of updater-demo for the current host platform.
#
# Run this on each release machine (mac-node1, lin-node1, win-node1) with
# the same VERSION value, collect the per-platform outputs into a single
# dist/ directory, then run scripts/release.sh VERSION from one machine
# to compute SHA256SUMS and attach everything to a GitHub release.
#
# Output: dist/updater-demo_<goos>_<goarch>[.exe]
#
# Bare binaries — no archive wrapper. The framework updater renames the
# downloaded asset onto the running binary's path, so the asset must
# itself be a runnable executable. Archives would land as the new
# "binary" and exec() would fail.
set -euo pipefail

VERSION="${VERSION:-}"
if [[ -z "$VERSION" ]]; then
  echo "VERSION env var required, e.g. VERSION=2.0.1 $0" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GOOS="$(go env GOOS)"
GOARCH="$(go env GOARCH)"
DIST="$REPO_ROOT/dist"
STEM="updater-demo_${GOOS}_${GOARCH}"
mkdir -p "$DIST"

# Wails apps need CGO + the production tag.
export CGO_ENABLED=1
LDFLAGS="-s -w -X main.version=${VERSION}"

case "$GOOS" in
  darwin | linux)
    OUT="$DIST/$STEM"
    rm -f "$OUT"
    go build -tags production -trimpath -ldflags "$LDFLAGS" -o "$OUT" ./...
    chmod 0755 "$OUT"
    ;;
  windows)
    OUT="$DIST/$STEM.exe"
    rm -f "$OUT"
    go build -tags production -trimpath -ldflags "$LDFLAGS -H windowsgui" -o "$OUT" ./...
    ;;
  *)
    echo "unsupported GOOS=$GOOS" >&2
    exit 2
    ;;
esac

echo
echo "Built: $OUT"
ls -la "$DIST"
