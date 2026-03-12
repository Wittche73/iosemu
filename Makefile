TARGET := iphone:clang:latest:15.0
ARCHS := arm64
DEBUG := 0
FOR_RELEASE := 1

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = LocalCompat

# Core Files (Unifying UI and Native Emulator Core logic for the launchable app)
LocalCompat_FILES = AppDelegate.swift SceneDelegate.swift \
    Models.swift FilesystemManager.swift JITBridge.swift GraphicsManager.swift \
    AudioManager.swift InputManager.swift PrefixManager.swift PerformanceManager.swift \
    WinetricksManager.swift WineDependencyManager.swift MetalFXManager.swift \
    CloudSyncManager.swift DisplayManager.swift ShaderCacheManager.swift \
    RegistryManager.swift MemoryPressureManager.swift \
    RuntimeLauncher.swift CommunityProfileManager.swift DynamicJITManager.swift \
    LibraryView.swift GameCardView.swift SettingsDashboard.swift \
    VirtualControllerView.swift PerformanceHUDView.swift \
    GameDiscoveryManager.swift MetalGameView.swift \
    RuntimeBridge.cpp \
    Core/CPU/XenonJitBackend.cpp \
    Core/GPU/XenosMetalRenderer.cpp \
    Core/Memory/XboxMemory.cpp \
    Core/Kernel/XboxKernel.cpp \
    Core/VFS/XboxFileSystem.cpp \
    Core/APU/AudioSystem.cpp \
    Core/HID/XInputManager.cpp

# Also include the advanced architecture from Sources
LocalCompat_FILES += $(shell find Sources -name "*.swift")

LocalCompat_SWIFTFLAGS = -import-objc-header LocalCompat-Bridging-Header.h
# XeniOS paths
XENIOS_ROOT = $(CURDIR)/../XeniOS-xenios
XENIOS_LIB = $(XENIOS_ROOT)/build/bin/iOS-ARM64/Release

LocalCompat_CFLAGS = -Ibin/box64/source/include -DREAL_ENGINE
LocalCompat_CCFLAGS = -std=c++20 \
    -I$(XENIOS_ROOT)/src \
    -I$(XENIOS_ROOT)/third_party/fmt/include \
    -I$(XENIOS_ROOT)/third_party/pugixml/src \
    -I$(XENIOS_ROOT)/third_party/FFmpeg \
    -I$(XENIOS_ROOT)/third_party/imgui \
    -I$(XENIOS_ROOT)/third_party/glslang \
    -I$(XENIOS_ROOT)/third_party/snappy \
    -I$(XENIOS_ROOT)/third_party/xxhash/include \
    -I$(XENIOS_ROOT)/third_party/mspack \
    -I$(XENIOS_ROOT)/third_party/cxxopts/include \
    -I$(XENIOS_ROOT)/third_party/tomlplusplus/include \
    -I$(XENIOS_ROOT)/third_party/zarchive/include \
    -DREAL_ENGINE
LocalCompat_FRAMEWORKS = UIKit Foundation GameController AVFoundation Metal MetalFX SwiftUI
LocalCompat_LDFLAGS = -L$(XENIOS_LIB) \
    -lxenia-kernel -lxenia-cpu -lxenia-cpu-backend-a64 \
    -lxenia-gpu -lxenia-apu -lxenia-apu-nop \
    -lxenia-hid -lxenia-hid-nop -lxenia-hid-skylander \
    -lxenia-ui -lxenia-vfs -lxenia-patcher \
    -lxenia-base -lxenia-core \
    -lfmt -lglslang-spirv -lspirv-cross -ldxbc \
    -llibavcodec -llibavformat -llibavutil \
    -lmspack -lsnappy -lxxhash -lpugixml \
    -laes_128 -lzlib-ng -lzstd -lzarchive
LocalCompat_LIBRARIES = c++

# Resources & Assets (Preventing flattening of directory structures)
LocalCompat_RESOURCE_FILES = Resources/Info.plist Resources/AppIcon60x60@2x.png

LocalCompat_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk

before-all::
	@echo "==> Preparing app layout..."
	@mkdir -p layout/Applications/LocalCompat.app/Frameworks
	@echo "==> Copying libbox64.dylib..."
	@cp Frameworks/libbox64.dylib layout/Applications/LocalCompat.app/Frameworks/
	@echo "==> Copying wine_payload recursively..."
	@rm -rf layout/Applications/LocalCompat.app/wine_payload
	@cp -R Resources/wine_payload layout/Applications/LocalCompat.app/
	@chmod -R 755 layout/Applications/LocalCompat.app/wine_payload
