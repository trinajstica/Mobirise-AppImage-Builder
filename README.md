# Mobirise AppImage Builder

A lightweight Bash script to automatically build a portable [AppImage](https://appimage.org/) for [Mobirise](https://mobirise.com) from the official `.deb` release.

Author: Barko  
Contributor: SimOne 😊  
License: MIT

---

## ✨ Features

- Downloads the latest release of Mobirise from the official site
- Extracts the `.deb` package contents
- Assembles a clean AppDir structure
- Builds an AppImage using `appimagetool`
- Works in your **current working directory**
- Supports `--verbose` mode for detailed output
- **Supports building from Mobirise beta releases** using the `--beta` parameter

---

## 🚀 Usage

```bash
./build-mobirise-appimage.sh [--beta] [--verbose]
