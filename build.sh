#!/bin/bash

# Exit immediately if any command fails
set -e

# Set THEOS path if not already set in environment
export THEOS="${THEOS:-/Users/huudung/theos}"

echo "=========================================="
echo "Starting AnyCar build script..."
echo "THEOS directory: $THEOS"
echo "=========================================="

# Create packages directory if it doesn't exist
mkdir -p packages

# 1. Build Rootful package (iphoneos-arm)
echo ""
echo "--> Building Rootful package..."
make clean
THEOS_PACKAGE_SCHEME= make package FINALPACKAGE=1

# 2. Build Rootless package (iphoneos-arm64)
echo ""
echo "--> Building Rootless package..."
make clean
THEOS_PACKAGE_SCHEME=rootless make package FINALPACKAGE=1

# Rename packages to explicitly include 'rootful' and 'rootless'
echo ""
echo "--> Renaming packages for clarity..."
for f in packages/*_iphoneos-arm.deb; do
    if [ -f "$f" ]; then
        mv "$f" "${f%_iphoneos-arm.deb}_rootful.deb"
    fi
done

for f in packages/*_iphoneos-arm64.deb; do
    if [ -f "$f" ]; then
        mv "$f" "${f%_iphoneos-arm64.deb}_rootless.deb"
    fi
done

echo ""
echo "=========================================="
echo "Build completed successfully!"
echo "Generated packages are in the 'packages' directory:"
ls -lh packages/*.deb
echo "=========================================="
