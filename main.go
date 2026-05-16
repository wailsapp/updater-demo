// updater-demo is the release target of v3/examples/updater. Each release
// of this repository ships a built binary for darwin/arm64, linux/amd64,
// and windows/amd64 plus a SHA256SUMS sidecar, so the v3 updater example
// can demonstrate the full check → download → verify → swap → restart
// flow end-to-end against a real GitHub release.
//
// The version the binary reports to the updater (and prints in the window
// header) is baked in at build time via:
//
//	go build -ldflags="-X main.version=2.0.0" ./...
package main

import (
	"context"
	"embed"
	"fmt"
	"log"

	"github.com/wailsapp/wails/v3/pkg/application"
	"github.com/wailsapp/wails/v3/pkg/updater"
	"github.com/wailsapp/wails/v3/pkg/updater/providers/github"
)

//go:embed assets
var assets embed.FS

// version is set at build time via -ldflags.
var version = "dev"

const repository = "wailsapp/updater-demo"

func main() {
	app := application.New(application.Options{
		Name:        fmt.Sprintf("Updater Demo v%s", version),
		Description: "Release target for the v3 updater example.",
		Assets: application.AssetOptions{
			Handler: application.BundledAssetFileServer(assets),
		},
		Mac: application.MacOptions{
			ApplicationShouldTerminateAfterLastWindowClosed: true,
		},
	})

	gh, err := github.New(github.Config{
		Repository:    repository,
		ChecksumAsset: "SHA256SUMS",
	})
	if err != nil {
		log.Fatalf("github.New: %v", err)
	}

	if err := app.Updater.Init(updater.Config{
		CurrentVersion: version,
		Providers:      []updater.Provider{gh},
	}); err != nil {
		log.Fatalf("updater.Init: %v", err)
	}

	app.Window.NewWithOptions(application.WebviewWindowOptions{
		Title:  fmt.Sprintf("Updater Demo v%s", version),
		Width:  640,
		Height: 480,
		URL:    "/?v=" + version,
	})

	menu := app.Menu.New()
	app.Menu.SetApplicationMenu(menu)
	appMenu := menu.AddSubmenu("App")
	appMenu.Add("Check for Updates…").OnClick(func(*application.Context) {
		go func() {
			if err := app.Updater.CheckAndInstall(context.Background()); err != nil {
				app.Logger.Error("update flow", "error", err)
			}
		}()
	})
	appMenu.AddSeparator()
	appMenu.Add("Quit").OnClick(func(*application.Context) { app.Quit() })

	for _, name := range []string{
		updater.EventUpdateAvailable,
		updater.EventDownloadProgress,
		updater.EventUpdateReady,
		updater.EventError,
	} {
		evt := name
		app.Event.On(evt, func(e *application.CustomEvent) {
			app.Logger.Info("updater", "event", evt, "data", e.Data)
		})
	}

	if err := app.Run(); err != nil {
		log.Fatal(err)
	}
}
