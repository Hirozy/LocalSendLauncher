# LocalSend Launcher for macOS

LocalSend Launcher is a small macOS wrapper that starts the real executable inside `/Applications/LocalSend.app` with a process-local proxy bypass for LocalSend's scoped IPv6 hostnames.

## Why this project exists

LocalSend can represent an IPv6 link-local destination with a synthetic hostname under `scoped.localsend.internal`. On a Mac with a system HTTP proxy enabled, a LocalSend request may be sent to the proxy. The proxy cannot resolve this application-internal hostname, so discovery may work while sending a file fails.

Adding `scoped.localsend.internal` to a macOS or proxy application's bypass list is not always sufficient because LocalSend's networking stack may not consume that list in the same way as a native Cocoa networking client. Setting `NO_PROXY=scoped.localsend.internal` for LocalSend itself avoids sending those requests to the proxy.

A shell command proves the workaround, but it is inconvenient for daily use. This launcher makes the workaround available from Finder, Dock, and Spotlight without changing LocalSend or the global GUI environment.

## What it does

When opened, the launcher:

1. Finds `/Applications/LocalSend.app`.
2. Reads `CFBundleExecutable` from LocalSend's current `Info.plist` instead of assuming a version-specific executable name.
3. Creates an environment for the LocalSend child process.
4. Removes inherited `HTTP_PROXY`, `HTTPS_PROXY`, and `ALL_PROXY` variables, including their lowercase forms.
5. Sets only:

   ```text
   NO_PROXY=scoped.localsend.internal
   no_proxy=scoped.localsend.internal
   ```

6. Starts LocalSend's real executable directly and exits.

The launcher does **not** modify `/Applications/LocalSend.app`, call `launchctl setenv`, disable the macOS system proxy, or configure `HTTP_PROXY`/`HTTPS_PROXY` for LocalSend.

## Requirements

- macOS 13 or later
- LocalSend installed at `/Applications/LocalSend.app`
- Apple Silicon or Intel Mac

## Using the app

1. Download and unzip `LocalSend-Launcher-macOS.zip`, or build the project as described below.
2. Move `LocalSend Launcher.app` to `/Applications` or another folder indexed by Spotlight.
3. Open `LocalSend Launcher.app` instead of opening LocalSend directly.
4. Optionally drag the launcher to the Dock.

The build script creates an ad-hoc signed app, not a notarized Developer ID release. On first launch, macOS may require you to Control-click the app and choose **Open**, or allow it in **System Settings > Privacy & Security**.

## Building from source

Install Xcode or the Xcode Command Line Tools, make sure LocalSend is installed in `/Applications`, then run:

```bash
git clone git@github.com:Hirozy/LocalSendLauncher.app.git
cd LocalSendLauncher.app
make build
```

The build produces:

```text
build/LocalSend Launcher.app
dist/LocalSend-Launcher-macOS.zip
```

The executable is compiled as a universal binary for both `arm64` and `x86_64`. The build copies LocalSend's installed icon into the launcher and applies a local ad-hoc code signature.

To remove generated files:

```bash
make clean
```

## Project layout

```text
Sources/main.swift       Launcher implementation
Resources/Info.plist     macOS application metadata
Scripts/build.sh         Universal app and ZIP build
Makefile                 Build and clean shortcuts
```
