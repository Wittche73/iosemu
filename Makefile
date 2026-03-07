TARGET := iphone:clang:latest:26.3
ARCHS := arm64
DEBUG := 0
FOR_RELEASE := 1

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = LocalCompat

# Core Files (Unifying UI and Simulation Logic for the launchable app)
LocalCompat_FILES = AppDelegate.swift SceneDelegate.swift \
    Models.swift FilesystemManager.swift JITBridge.swift GraphicsManager.swift \
    AudioManager.swift InputManager.swift PrefixManager.swift PerformanceManager.swift \
    WinetricksManager.swift WineDependencyManager.swift MetalFXManager.swift \
    CloudSyncManager.swift DisplayManager.swift ShaderCacheManager.swift \
    RuntimeLauncher.swift CommunityProfileManager.swift DynamicJITManager.swift \
    LibraryView.swift GameCardView.swift SettingsDashboard.swift \
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
	@echo "==> Creating app layout directories..."
	@mkdir -p layout/Applications/LocalCompat.app/Frameworks
	@echo "==> Copying genuine libbox64.dylib into app payload..."
	@cp Frameworks/libbox64.dylib layout/Applications/LocalCompat.app/Frameworks/libbox64.dylib
	@echo "==> Copying wine_payload into app payload..."
	@cp -r Resources/wine_payload layout/Applications/LocalCompat.app/
