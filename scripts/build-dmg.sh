#!/usr/bin/env bash
set -euo pipefail

# Build CodeIsland.app and package it as a DMG under .build/.
#
# Usage:
#   ./scripts/build-dmg.sh [--skip-build] [--notarize] [--output .build/CodeIsland.dmg]
#
# Environment:
#   SIGN_ID=<identity>        Forwarded to build.sh for app signing.
#   DMG_SIGN_ID=<identity>    Optional identity for signing the DMG container.

APP_NAME="CodeIsland"

usage() {
    cat <<'EOF'
Usage: ./scripts/build-dmg.sh [--skip-build] [--notarize] [--output <path>]

  --skip-build      Reuse .build/dist/CodeIsland.app
  --notarize        Forward --notarize to ./build.sh before packaging
  --output <path>   DMG output path (default: .build/CodeIsland.dmg)
  --help            Show this help
EOF
}

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/.build"
DIST_DIR="$BUILD_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
STAGING_DIR="$BUILD_DIR/dmg-staging"
OUTPUT_DMG="$BUILD_DIR/$APP_NAME.dmg"
SKIP_BUILD=false
NOTARIZE=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --notarize)
            NOTARIZE=true
            shift
            ;;
        --output)
            if [ "$#" -lt 2 ]; then
                echo "Missing value for --output" >&2
                usage >&2
                exit 1
            fi
            OUTPUT_DMG="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

cd "$REPO_ROOT"
mkdir -p "$BUILD_DIR"

if [ "$SKIP_BUILD" = false ]; then
    echo "==> Building $APP_NAME.app"
    BUILD_ARGS=()
    if [ "$NOTARIZE" = true ]; then
        BUILD_ARGS+=(--notarize)
    fi
    ./build.sh "${BUILD_ARGS[@]}"
fi

if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: app bundle not found: $APP_BUNDLE" >&2
    echo "Run ./build.sh first, or omit --skip-build." >&2
    exit 1
fi

echo "==> Staging DMG contents"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
ditto "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$OUTPUT_DMG"
mkdir -p "$(dirname "$OUTPUT_DMG")"

echo "==> Creating $OUTPUT_DMG"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$OUTPUT_DMG"

if [ -n "${DMG_SIGN_ID:-}" ]; then
    echo "==> Signing DMG with $DMG_SIGN_ID"
    codesign --force --sign "$DMG_SIGN_ID" "$OUTPUT_DMG"
fi

echo "==> Done: $OUTPUT_DMG"
