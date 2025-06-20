#!/bin/bash

# ========================================================
#  Script for building Mobirise AppImage
#  Author: Barko
#  Contributor: SimOne 😊
#  Source: https://download.mobirise.com/MobiriseSetup.deb
#  License: MIT License
#  Description: This script downloads, extracts, and creates
#  an AppImage for the Mobirise application. Everything runs
#  in the user's current working directory.
#  Use --verbose to display detailed output;
#  otherwise, only basic progress is shown.
# ========================================================

# Check if the --verbose parameter was provided
VERBOSE=false
if [ "$1" = "--verbose" ]; then
    VERBOSE=true
    shift
fi

echo "========================================"
echo " Script: Mobirise AppImage Builder"
echo " Author: Barko"
echo " Contributor: SimOne 😊"
echo " Source: https://download.mobirise.com/MobiriseSetup.deb"
echo "========================================"
echo ""

APP="Mobirise"
ROOT="$(pwd)"

# URL to the .deb package and file paths
DEB_URL="https://download.mobirise.com/MobiriseSetup.deb"
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

    # Check if /opt/Mobirise actually exists
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

# Copy contents of opt/Mobirise from working directory
if [ "$VERBOSE" = true ]; then
    cp -rv "opt/Mobirise/"* "$APPDIR/opt/Mobirise/"
else
    cp -r "opt/Mobirise/"* "$APPDIR/opt/Mobirise/" 2>/dev/null
fi

# Find first .desktop file and rename it
DESKTOP_SRC=$(ls usr/share/applications/*.desktop 2>/dev/null | head -n1)
if [ -z "$DESKTOP_SRC" ] || [ ! -f "$DESKTOP_SRC" ]; then
    echo "❌ Did not find .desktop file in usr/share/applications."
    exit 1
fi
cp "$DESKTOP_SRC" "$APPDIR/mobirise.desktop"

# Copy icon (first .png in 256x256/apps)
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
# Run executable from opt/Mobirise
exec "${HERE}/opt/Mobirise/${APP}" "$@"
EOF
chmod +x "$APPDIR/AppRun"

#
# 7) Run appimagetool to build .AppImage
#
echo "🚀 Building AppImage..."
cd "$ROOT" || exit 1

# If an older file exists, remove it to avoid rename issues
if [ -f "$IMAGE_OUT" ]; then
    rm -f "$IMAGE_OUT"
fi

if [ "$VERBOSE" = true ]; then
    ARCH=x86_64 "$APPIMAGETOOL" -n --verbose "$APPDIR" "$IMAGE_OUT"
else
    ARCH=x86_64 "$APPIMAGETOOL" -n "$APPDIR" "$IMAGE_OUT" > /dev/null 2>&1
fi

# Check if AppImage was created
if [ ! -f "$IMAGE_OUT" ]; then
    echo "❌ AppImage was not created. Check for errors above."
    exit 1
else
    echo "✅ AppImage for $APP is ready: $IMAGE_OUT"
fi
echo ""

#
# 8) Clean up temporary folders
#
echo "🧹 Cleaning up temporary files..."
rm -rf "$WORKDIR"
rm -rf "$APPDIR"
rm -f "$DEB_FILE"
echo "🧹 Done. Enjoy mobirise.AppImage! 😃"
