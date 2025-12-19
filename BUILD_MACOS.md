# Building Notepad++ for macOS

## Prerequisites

### Required Tools
- **macOS 11.0 (Big Sur) or later**
- **Xcode 13.0 or later** (for Apple Silicon support)
- **CMake 3.20 or later**

Install CMake via Homebrew:
```bash
brew install cmake
```

### Supported Architectures
- **ARM64** (Apple Silicon: M1, M2, M3, M4)
- Intel x86_64 support can be added by modifying `CMAKE_OSX_ARCHITECTURES`

## Build Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/notepad-plus-plus/notepad-plus-plus.git notepad-plus-plus_macos
cd notepad-plus-plus_macos
```

### 2. Configure with CMake
```bash
# Create build directory
mkdir build
cd build

# Configure for Apple Silicon (ARM64)
cmake .. -G Xcode -DCMAKE_OSX_ARCHITECTURES=arm64

# Alternative: Configure for Intel
# cmake .. -G Xcode -DCMAKE_OSX_ARCHITECTURES=x86_64

# Alternative: Universal binary (both architectures)
# cmake .. -G Xcode -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
```

### 3. Build the Project

**Option A: Using Xcode**
```bash
# Open the generated Xcode project
open NotepadPlusPlus.xcodeproj

# Build from Xcode GUI (Cmd+B)
```

**Option B: Using Command Line**
```bash
# Build Release configuration
cmake --build . --config Release

# Build Debug configuration
cmake --build . --config Debug
```

### 4. Run the Application
```bash
# After building, the app bundle will be in:
# build/bin/Release/notepadpp.app (Release build)
# build/bin/Debug/notepadpp.app (Debug build)

# Run the app
open bin/Release/notepadpp.app
```

## Current Status

⚠️ **IMPORTANT: This is a work in progress!**

### ✅ Completed (Phase 1)
- [x] CMake build system for macOS
- [x] Scintilla library configuration (Cocoa platform)
- [x] Lexilla library configuration
- [x] BoostRegex library configuration
- [x] Info.plist for macOS app bundle
- [x] ARM64 architecture support

### 🚧 In Progress
- [ ] Platform abstraction layer
- [ ] macOS entry point (main_mac.mm)
- [ ] Cocoa UI implementation

### ❌ Not Yet Implemented
- [ ] Window management (NSWindow/NSView)
- [ ] Menu bar (NSMenu)
- [ ] Dialogs (Find/Replace, Preferences, etc.)
- [ ] File operations (POSIX/FSEvents)
- [ ] Settings persistence (NSUserDefaults)
- [ ] Plugin system (dylib loading)
- [ ] macOS-specific features (Dock, Services, etc.)

## Known Issues

1. **Build will fail** - The current CMakeLists.txt references source files that don't exist yet (main_mac.mm, platform abstraction layer, etc.)
2. **Scintilla Cocoa sources** - Need to verify Scintilla's Cocoa implementation exists and is compatible
3. **Windows dependencies** - Many source files still use Windows-specific APIs and won't compile on macOS

## Next Steps

To make this buildable, the following files need to be created:

1. **Platform Abstraction Layer**
   - `PowerEditor/src/platform/PlatformTypes.h`
   - `PowerEditor/src/platform/WindowManager_mac.mm`
   - `PowerEditor/src/platform/FileSystem_mac.mm`

2. **macOS Entry Point**
   - `PowerEditor/src/main_mac.mm` (replace winmain.cpp)

3. **Cocoa UI Components**
   - `PowerEditor/src/cocoa/NotepadPlusWindow.mm`
   - `PowerEditor/src/cocoa/AppDelegate.mm`

See `implementation_plan.md` for the complete roadmap.

## Development Workflow

### Testing Build Configuration
```bash
# Clean build
rm -rf build
mkdir build && cd build

# Configure and build
cmake .. -G Xcode -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build . --config Debug

# Check for errors
echo $?  # Should be 0 if successful
```

### Checking Binary Architecture
```bash
# Verify the binary is built for correct architecture
file bin/Release/notepadpp.app/Contents/MacOS/notepadpp

# Expected output for ARM64:
# Mach-O 64-bit executable arm64
```

## Troubleshooting

### CMake Configuration Fails
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`
- Verify CMake version: `cmake --version` (should be 3.20+)

### Build Fails with Missing Headers
- This is expected - source files need to be created/ported
- Follow the implementation plan phases in order

### Scintilla Cocoa Sources Not Found
- Check if `scintilla/cocoa/` directory exists
- May need to update Scintilla to a version with macOS support

## Contributing

This is a massive porting effort. Contributions are welcome!

Priority areas:
1. Platform abstraction layer implementation
2. Cocoa UI components
3. File system operations
4. Testing on different macOS versions and Apple Silicon variants

## License

Notepad++ is licensed under GPL v3. See LICENSE file for details.
