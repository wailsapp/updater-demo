#!/usr/bin/env bash
# build.sh — native build of updater-demo for the current host platform.
#
# Run this on each release machine (mac-node1, lin-node1, win-node1) with
# the same VERSION value, collect the per-platform archives into a single
# dist/ directory, then run scripts/release.sh VERSION from one machine
# to compute SHA256SUMS and attach everything to a GitHub release.
#
# Output: dist/updater-demo_<goos>_<goarch>.<ext>
set -euo pipefail

VERSION="${VERSION:-}"
if [[ -z "$VERSION" ]]; then
  echo "VERSION env var required, e.g. VERSION=2.0.0 $0" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GOOS="$(go env GOOS)"
GOARCH="$(go env GOARCH)"
DIST="$REPO_ROOT/dist"
STEM="updater-demo_${GOOS}_${GOARCH}"
mkdir -p "$DIST"

# Wails apps need CGO + the production tag (selects the right webview
# backend and disables dev-time logging).
export CGO_ENABLED=1
LDFLAGS="-s -w -X main.version=${VERSION}"

case "$GOOS" in
  darwin)
    rm -f "$DIST/$STEM" "$DIST/$STEM.tar.gz"
    go build -tags production -trimpath -ldflags "$LDFLAGS" -o "$DIST/$STEM" ./...
    (cd "$DIST" && tar -czf "$STEM.tar.gz" "$STEM")
    rm -f "$DIST/$STEM"
    ;;
  linux)
    rm -f "$DIST/$STEM" "$DIST/$STEM.tar.gz"
    go build -tags production -trimpath -ldflags "$LDFLAGS" -o "$DIST/$STEM" ./...
    (cd "$DIST" && tar -czf "$STEM.tar.gz" "$STEM")
    rm -f "$DIST/$STEM"
    ;;
  windows)
    EXE="$STEM.exe"
    rm -f "$DIST/$EXE" "$DIST/$STEM.zip"
    go build -tags production -trimpath -ldflags "$LDFLAGS -H windowsgui" -o "$DIST/$EXE" ./...
    (cd "$DIST" && zip -q "$STEM.zip" "$EXE")
    rm -f "$DIST/$EXE"
    ;;
  *)
    echo "unsupported GOOS=$GOOS" >&2
    exit 2
    ;;
esac

echo
echo "Built: $DIST/$STEM.*"
ls -la "$DIST"
