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

# Resources & Assets (Crucial for a non-broken IPA)
LocalCompat_RESOURCE_FILES = $(shell find Resources -type f)

LocalCompat_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk

before-all::
	@echo "==> Creating dummy framework directories..."
	@mkdir -p layout/Applications/LocalCompat.app/Frameworks
	@echo "==> Generating dummy libbox64.dylib for dlopen testing..."
	@echo "void box64_main(int argc, const char** argv) { }" > dummy.c
	@$(CC) -dynamiclib -o layout/Applications/LocalCompat.app/Frameworks/libbox64.dylib dummy.c
	@rm dummy.c
