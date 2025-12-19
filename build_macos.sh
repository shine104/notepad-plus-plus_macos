#!/bin/bash

# Build script for Notepad++ macOS
# This script builds the project and provides helpful output

set -e  # Exit on error

echo "================================================"
echo "  Notepad++ for macOS - Build Script"
echo "================================================"
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS"
    exit 1
fi

# Check for CMake
if ! command -v cmake &> /dev/null; then
    echo "❌ Error: CMake not found"
    echo "Install with: brew install cmake"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Build configuration
BUILD_TYPE="${1:-Debug}"
ARCHITECTURE="${2:-arm64}"

echo "Configuration:"
echo "  Build Type: $BUILD_TYPE"
echo "  Architecture: $ARCHITECTURE"
echo ""

# Create build directory
BUILD_DIR="build"
if [ -d "$BUILD_DIR" ]; then
    echo "📁 Build directory exists"
else
    echo "📁 Creating build directory..."
    mkdir -p "$BUILD_DIR"
fi

cd "$BUILD_DIR"

# Configure with CMake
echo ""
echo "⚙️  Configuring with CMake..."
cmake .. \
    -G Xcode \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHITECTURE" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ CMake configuration failed"
    exit 1
fi

# Build
echo ""
echo "🔨 Building..."
cmake --build . --config "$BUILD_TYPE" -j $(sysctl -n hw.ncpu)

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build failed"
    exit 1
fi

# Success!
echo ""
echo "================================================"
echo "  ✅ Build Successful!"
echo "================================================"
echo ""

# Find the app bundle
APP_PATH="bin/$BUILD_TYPE/notepadpp.app"

if [ -d "$APP_PATH" ]; then
    echo "📦 App bundle created: $APP_PATH"
    echo ""
    
    # Get binary info
    BINARY_PATH="$APP_PATH/Contents/MacOS/notepadpp"
    if [ -f "$BINARY_PATH" ]; then
        echo "Binary information:"
        file "$BINARY_PATH"
        echo ""
        
        # Get size
        SIZE=$(du -h "$BINARY_PATH" | cut -f1)
        echo "Binary size: $SIZE"
        echo ""
    fi
    
    echo "To run the application:"
    echo "  open $APP_PATH"
    echo ""
    echo "Or from the build directory:"
    echo "  cd $SCRIPT_DIR/$BUILD_DIR"
    echo "  open $APP_PATH"
    echo ""
else
    echo "⚠️  Warning: App bundle not found at expected location"
    echo "Looking for: $APP_PATH"
fi

echo "================================================"
