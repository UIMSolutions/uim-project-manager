#!/bin/bash
set -e

APP_ID="io.github.yourname.DProjectManager"
MANIFEST="flatpak/${APP_ID}.json"

echo "================================================"
echo "Building Flatpak for D Project Manager"
echo "================================================"

# Check if flatpak-builder is installed
if ! command -v flatpak-builder &> /dev/null; then
    echo "Error: flatpak-builder is not installed"
    echo "Install with: sudo apt install flatpak-builder"
    exit 1
fi

# Add Flathub repository if not already added
echo "Ensuring Flathub repository is available..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install required runtime
echo "Installing GNOME Platform runtime..."
flatpak install -y flathub org.gnome.Platform//45 org.gnome.Sdk//45 || true

# Build the Flatpak
echo "Building Flatpak package..."
flatpak-builder --force-clean --repo=repo build-dir "${MANIFEST}"

# Install locally for testing
echo "Installing locally for testing..."
flatpak-builder --user --install --force-clean build-dir "${MANIFEST}"

# Create single-file bundle for distribution
echo "Creating distributable bundle..."
flatpak build-bundle repo d-project-manager.flatpak "${APP_ID}"

echo ""
echo "================================================"
echo "Build complete!"
echo "================================================"
echo "Testing: flatpak run ${APP_ID}"
echo "Uninstall: flatpak uninstall ${APP_ID}"
echo ""
echo "Distributable file created: d-project-manager.flatpak"
echo "Users can install with: flatpak install d-project-manager.flatpak"
echo ""
