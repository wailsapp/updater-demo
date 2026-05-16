#!/usr/bin/env bash
# release.sh — compute SHA256SUMS for every archive in dist/, then create
# a GitHub release with all of them attached.
#
# Pre-requisite: build.sh has been run on each release machine and the
# resulting dist/updater-demo_<goos>_<goarch>.<ext> archives have been
# scp'd into the same dist/ directory on the orchestrating host.
#
# Usage:
#   scripts/release.sh 2.0.0
set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "usage: $0 <version-without-leading-v>" >&2
  exit 2
fi
TAG="v${VERSION}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$REPO_ROOT/dist"

if [[ ! -d "$DIST" ]] || [[ -z "$(ls -A "$DIST"/updater-demo_*.* 2>/dev/null || true)" ]]; then
  echo "no archives found in $DIST — run build.sh on each platform first" >&2
  exit 3
fi

cd "$DIST"

echo "Archives to release:"
ls -la updater-demo_*.*

# SHA256SUMS sidecar — one line per archive in the canonical `sha256sum`
# format the github provider's parseChecksumLine understands.
SUMS="SHA256SUMS"
rm -f "$SUMS"
for f in updater-demo_*.*; do
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" >> "$SUMS"
  else
    sha256sum "$f" >> "$SUMS"
  fi
done

echo
echo "=== $SUMS ==="
cat "$SUMS"
echo

read -r -p "Create release $TAG with these assets? [y/N] " ack
if [[ "$ack" != "y" && "$ack" != "Y" ]]; then
  echo "aborted"
  exit 1
fi

# shellcheck disable=SC2046
gh release create "$TAG" \
  --repo wailsapp/updater-demo \
  --title "$TAG" \
  --notes "Demo release v${VERSION} for v3/examples/updater. Platform archives + SHA256SUMS sidecar; verification uses Config.ChecksumAsset=\"SHA256SUMS\"." \
  $(ls updater-demo_*.* SHA256SUMS)

echo
echo "Released: https://github.com/wailsapp/updater-demo/releases/tag/$TAG"
