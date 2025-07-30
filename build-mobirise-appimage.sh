#!/bin/bash

# ========================================================
#  Script for building Mobirise AppImage
#  Author: Barko
#  Contributor: SimOne 😊
#  License: MIT License
#  Description: This script downloads, extracts, and creates
#  an AppImage for the Mobirise application. Everything runs
#  in the user's current working directory.
#  Supports --beta to build from the beta channel.
#  Use --verbose to display detailed output; otherwise,
#  only basic progress is shown.
# ========================================================

# Check flags
VERBOSE=false
BETA=false

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --verbose)
            VERBOSE=true
            ;;
        --beta)
            BETA=true
            ;;
    esac
    shift
done

echo "========================================"
echo " Script: Mobirise AppImage Builder"
echo " Author: Barko"
echo " Contributor: SimOne 😊"
if [ "$BETA" = true ]; then
    echo " Build:   Beta"
else
    echo " Build:   Stable"
fi
echo "========================================"
echo ""

APP="Mobirise"
ROOT="$(pwd)"

# URL to the .deb package based on channel
if [ "$BETA" = true ]; then
    DEB_URL="https://download.mobirise.com/beta/mobirise-beta.deb"
else
    DEB_URL="https://download.mobirise.com/MobiriseSetup.deb"
fi
DEB_FILE="$ROOT/MobiriseSetup.deb"
WORKDIR="$ROOT/mobirise_build"
APPDIR="$ROOT/${APP}.AppDir"
IMAGE_OUT="$ROOT/mobirise.AppImage"

#
# 1) Prepare working directory
#
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR" || { echo "❌ Cannot enter $WORKDIR"; exit 1; }

#
# 2) Check for appimagetool or download locally
#
if command -v appimagetool &>/dev/null; then
    APPIMAGETOOL="appimagetool"
    echo "✅ Using system appimagetool"
else
    APPIMAGETOOL="$ROOT/appimagetool"
    if [ ! -x "$APPIMAGETOOL" ]; then
        echo "⬇️ Downloading local copy of appimagetool..."
        if [ "$VERBOSE" = true ]; then
            wget -O "$APPIMAGETOOL" \
                "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$(uname -m).AppImage"
        else
            wget -q -O "$APPIMAGETOOL" \
                "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$(uname -m).AppImage"
        fi
        chmod a+x "$APPIMAGETOOL"
    else
        echo "✅ Using existing local copy of appimagetool"
    fi
fi
echo ""

#
# 3) Download .deb package
#
if [ ! -f "$DEB_FILE" ]; then
    echo "⬇️ Downloading Mobirise .deb package..."
    if [ "$VERBOSE" = true ]; then
        wget -O "$DEB_FILE" "$DEB_URL"
    else
        wget -q -O "$DEB_FILE" "$DEB_URL"
    fi

    if [ ! -f "$DEB_FILE" ]; then
        echo "❌ Failed to download .deb package."
        exit 1
    fi
    echo ""
else
    echo "ℹ️ .deb package already exists: $DEB_FILE"
    echo ""
fi

#
# 4) Extract .deb (ar + tar)
#
if [ ! -f "$WORKDIR/debian-binary" ]; then
    echo "📦 Extracting .deb content..."
    if [ "$VERBOSE" = true ]; then
        ar x "$DEB_FILE"
        tar xvf data.tar.*
    else
        ar x "$DEB_FILE" 2>/dev/null
        tar xf data.tar.* 2>/dev/null
    fi

    if [ ! -d "opt/Mobirise" ]; then
        echo "❌ .deb structure does not contain opt/Mobirise. Check the contents."
        exit 1
    fi
    echo ""
else
    echo "ℹ️ .deb already extracted."
    echo ""
fi

#
# 5) Prepare AppDir structure
#
echo "🔧 Preparing AppDir for $APP..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/opt/Mobirise"

if [ "$VERBOSE" = true ]; then
    cp -rv "opt/Mobirise/"* "$APPDIR/opt/Mobirise/"
else
    cp -r "opt/Mobirise/"* "$APPDIR/opt/Mobirise/" 2>/dev/null
fi

DESKTOP_SRC=$(ls usr/share/applications/*.desktop 2>/dev/null | head -n1)
if [ -z "$DESKTOP_SRC" ] || [ ! -f "$DESKTOP_SRC" ]; then
    echo "❌ Did not find .desktop file in usr/share/applications."
    exit 1
fi
cp "$DESKTOP_SRC" "$APPDIR/mobirise.desktop"

ICON_SRC=$(ls usr/share/icons/hicolor/256x256/apps/*.png 2>/dev/null | head -n1)
if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$APPDIR/mobirise.png"
else
    echo "⚠️ Did not find icon in usr/share/icons/hicolor/256x256/apps/*.png. Continuing without icon."
fi
echo ""

#
# 6) Create AppRun
#
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/sh
APP="mobirise"
HERE="$(dirname "$(readlink -f "${0}")")"
exec "${HERE}/opt/Mobirise/${APP}" "$@"
EOF
chmod +x "$APPDIR/AppRun"

#
# 7) Build .AppImage
#
echo "🚀 Building AppImage..."
cd "$ROOT" || exit 1

[ -f "$IMAGE_OUT" ] && rm -f "$IMAGE_OUT"

if [ "$VERBOSE" = true ]; then
    ARCH=x86_64 "$APPIMAGETOOL" -n --verbose "$APPDIR" "$IMAGE_OUT"
else
    ARCH=x86_64 "$APPIMAGETOOL" -n "$APPDIR" "$IMAGE_OUT" > /dev/null 2>&1
fi

if [ ! -f "$IMAGE_OUT" ]; then
    echo "❌ AppImage was not created. Check for errors above."
    exit 1
else
    echo "✅ AppImage for $APP is ready: $IMAGE_OUT"
fi
echo ""

#
# 8) Clean up
#
echo "🧹 Cleaning up temporary files..."
rm -rf "$WORKDIR" "$APPDIR" "$DEB_FILE"
echo "🧹 Done. Enjoy mobirise.AppImage! 😃"

