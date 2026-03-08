TARGET := iphone:clang:latest:26.3
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
    RuntimeBridge.cpp

# Also include the advanced architecture from Sources
LocalCompat_FILES += $(shell find Sources -name "*.swift")

LocalCompat_SWIFTFLAGS = -import-objc-header LocalCompat-Bridging-Header.h
LocalCompat_CFLAGS = -Ibin/box64/source/include -DREAL_ENGINE
LocalCompat_FRAMEWORKS = UIKit Foundation GameController AVFoundation Metal MetalFX SwiftUI
LocalCompat_LIBRARIES = stdc++

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
