#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
APP_NAME="LocalSend Launcher"
BUILD_ROOT="$PROJECT_ROOT/build"
DIST_ROOT="$PROJECT_ROOT/dist"
APP_PATH="$BUILD_ROOT/$APP_NAME.app"
EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/$APP_NAME"
MODULE_CACHE="${TMPDIR:-/tmp}/localsend-launcher-module-cache"
APP_ICON="$PROJECT_ROOT/Resources/AppIcon.icns"

for tool in swiftc lipo codesign ditto; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required build tool not found: $tool" >&2
        exit 1
    fi
done

if [[ ! -f "$APP_ICON" ]]; then
    echo "Bundled app icon not found: $APP_ICON" >&2
    exit 1
fi

rm -rf "$BUILD_ROOT" "$DIST_ROOT"
mkdir -p \
    "$BUILD_ROOT/arm64" \
    "$BUILD_ROOT/x86_64" \
    "$APP_PATH/Contents/MacOS" \
    "$APP_PATH/Contents/Resources" \
    "$DIST_ROOT" \
    "$MODULE_CACHE"

SWIFT_MODULECACHE_PATH="$MODULE_CACHE" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
swiftc -O \
    -target arm64-apple-macos13.0 \
    -framework AppKit \
    "$PROJECT_ROOT/Sources/main.swift" \
    -o "$BUILD_ROOT/arm64/$APP_NAME"

SWIFT_MODULECACHE_PATH="$MODULE_CACHE" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
swiftc -O \
    -target x86_64-apple-macos13.0 \
    -framework AppKit \
    "$PROJECT_ROOT/Sources/main.swift" \
    -o "$BUILD_ROOT/x86_64/$APP_NAME"

lipo -create \
    "$BUILD_ROOT/arm64/$APP_NAME" \
    "$BUILD_ROOT/x86_64/$APP_NAME" \
    -output "$EXECUTABLE_PATH"

cp "$PROJECT_ROOT/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$APP_ICON" "$APP_PATH/Contents/Resources/AppIcon.icns"
chmod 755 "$EXECUTABLE_PATH"

# Remove filesystem metadata that can interfere with signing, then apply a local
# ad-hoc signature. Distribution builds should use a Developer ID instead.
xattr -cr "$APP_PATH"
codesign --force --deep --sign - --timestamp=none "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

ditto -c -k --sequesterRsrc --keepParent \
    "$APP_PATH" \
    "$DIST_ROOT/LocalSend-Launcher-macOS.zip"

echo "Built: $APP_PATH"
echo "Archive: $DIST_ROOT/LocalSend-Launcher-macOS.zip"
