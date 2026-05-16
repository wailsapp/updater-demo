# updater-demo

Release target for the Wails v3 updater example
([`v3/examples/updater`](https://github.com/wailsapp/wails/pull/5449) —
the feature is still on a branch; this link follows the PR).
Each tagged release of this repository ships pre-built binaries for
darwin/arm64, linux/amd64, and windows/amd64 plus a `SHA256SUMS`
sidecar, so the example can demonstrate the full update flow
end-to-end against a real GitHub release.

> This repo is **not** a starter template. For that, run `wails3 init`.
> This is the artifact source the framework's updater example downloads
> from when you click **App → Check for Updates…**

## What the binary does

It opens a single window that prints its own version in big letters
and mirrors `updater:*` events into a status panel. The version is
baked in at build time via `-ldflags="-X main.version=<v>"`, so
v1.0.0 and v2.0.0 are visually distinguishable.

## Cutting a release

Releases are built natively on three machines and combined manually
— there's no CI here on purpose (the demo is small, the manual flow
is transparent).

1. **On each platform**, clone the repo and run:

   ```sh
   VERSION=2.0.0 scripts/build.sh
   ```

   produces `dist/updater-demo_<goos>_<goarch>.<ext>`.

2. **Collect** all archives into a single host's `dist/` directory
   via `scp` and run:

   ```sh
   scripts/release.sh 2.0.0
   ```

   which computes `SHA256SUMS` and `gh release create`s the tag with
   every archive attached.

## Platform notes

- **darwin**: plain `tar.gz` of the binary, not a `.app` bundle. The
  updater's helper does a direct `exec.Command(target)` on swap, so
  the runtime form matches whatever the calling app is — keeping
  this a plain binary avoids `.app`-vs-binary swap-type mismatches.
- **linux**: depends on `libgtk-3` and `libwebkit2gtk-4.1` at runtime.
- **windows**: built with `-H windowsgui` so the binary has no
  console window when launched. Requires WebView2 Runtime on the
  user's machine (preinstalled on Win10 1903+).

## License

MIT — see [LICENSE](./LICENSE).
