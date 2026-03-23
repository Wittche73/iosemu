// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LocalCompat",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "LocalCompat", targets: ["LocalCompat"]),
        .library(name: "CompatCore", targets: ["CompatCore"]),
        .library(name: "CompatUIKit", targets: ["CompatUIKit"]),
    ],
    targets: [
        .target(
            name: "LocalCompat",
            dependencies: [
                "CompatCore",
                "CompatUIKit",
                "LocalCompatBridge"
            ],
            path: ".",
            exclude: [
                "Package.swift", "Makefile", "control", "xtool.yml", "build_full.log",
                "proje_ozeti.md", "task.md", "hata_cozumleri.md", "detay.md",
                "lib", "Frameworks", "layout", "bin", ".theos", ".github", "Resources",
                "RuntimeBridge.cpp", "RuntimeBridge.h", "Core"
            ],
            sources: [
                "AppDelegate.swift", "SceneDelegate.swift", "Models.swift",
                "FilesystemManager.swift", "JITBridge.swift", "GraphicsManager.swift",
                "AudioManager.swift", "InputManager.swift", "PrefixManager.swift",
                "PerformanceManager.swift", "WinetricksManager.swift", "WineDependencyManager.swift",
                "MetalFXManager.swift", "CloudSyncManager.swift", "DisplayManager.swift",
                "ShaderCacheManager.swift", "RegistryManager.swift", "MemoryPressureManager.swift",
                "RuntimeLauncher.swift", "CommunityProfileManager.swift", "DynamicJITManager.swift",
                "LibraryView.swift", "GameCardView.swift", "SettingsDashboard.swift",
                "VirtualControllerView.swift", "PerformanceHUDView.swift",
                "GameDiscoveryManager.swift", "MetalGameView.swift",
                "TestCore.swift", "TestFS.swift", "TestJIT.swift"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-import-objc-header", "LocalCompat-Bridging-Header.h",
                    "-Xcc", "-resource-dir", "-Xcc", "/home/f-rat/.local/share/swiftly/toolchains/6.2.3/usr/lib/clang/17",
                    "-Xcc", "-I", "-Xcc", "/home/f-rat/.local/share/swiftly/toolchains/6.2.3/usr/lib/clang/17/include"
                ])
            ]
        ),
        .target(
            name: "LocalCompatBridge",
            path: ".",
            exclude: [
                "Package.swift", "Makefile", "control", "xtool.yml", "build_full.log",
                "proje_ozeti.md", "task.md", "hata_cozumleri.md", "detay.md",
                "lib", "Frameworks", "layout", "bin", ".theos", ".github", "Resources",
                "AppDelegate.swift", "SceneDelegate.swift", "Models.swift",
                "FilesystemManager.swift", "JITBridge.swift", "GraphicsManager.swift",
                "AudioManager.swift", "InputManager.swift", "PrefixManager.swift",
                "PerformanceManager.swift", "WinetricksManager.swift", "WineDependencyManager.swift",
                "MetalFXManager.swift", "CloudSyncManager.swift", "DisplayManager.swift",
                "ShaderCacheManager.swift", "RegistryManager.swift", "MemoryPressureManager.swift",
                "RuntimeLauncher.swift", "CommunityProfileManager.swift", "DynamicJITManager.swift",
                "LibraryView.swift", "GameCardView.swift", "SettingsDashboard.swift",
                "VirtualControllerView.swift", "PerformanceHUDView.swift",
                "GameDiscoveryManager.swift", "MetalGameView.swift",
                "TestCore.swift", "TestFS.swift", "TestJIT.swift",
                "LocalCompat-Bridging-Header.h", "Sources", "Tests"
            ],
            sources: [
                "RuntimeBridge.cpp",
                "Core"
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("bin/box64/source/include"),
                .define("REAL_ENGINE"),
                .unsafeFlags([
                    "-Umacos", "-Uios",
                    "-resource-dir", "/home/f-rat/.local/share/swiftly/toolchains/6.2.3/usr/lib/clang/17",
                    "-I", "/home/f-rat/.local/share/swiftly/toolchains/6.2.3/usr/lib/clang/17/include"
                ])
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
                .unsafeFlags([
                    "-L", "lib/xenia",
                    "-lxenia-kernel", "-lxenia-cpu", "-lxenia-cpu-backend-a64",
                    "-lxenia-gpu", "-lxenia-apu", "-lxenia-apu-nop",
                    "-lxenia-hid", "-lxenia-hid-nop", "-lxenia-hid-skylander",
                    "-lxenia-ui", "-lxenia-vfs", "-lxenia-patcher",
                    "-lxenia-base", "-lxenia-core",
                    "-lfmt", "-lglslang-spirv", "-lspirv-cross", "-ldxbc",
                    "-llibavcodec", "-llibavformat", "-llibavutil",
                    "-lmspack", "-lsnappy", "-lxxhash", "-lpugixml",
                    "-laes_128", "-lzlib-ng", "-lzstd", "-lzarchive"
                ])
            ]
        ),
        .target(name: "CompatCore", dependencies: ["LocalCompatBridge"], path: "Sources/CompatCore"),
        .target(name: "CompatUIKit", dependencies: ["CompatCore"], path: "Sources/CompatUIKit"),
        .testTarget(name: "CompatCoreTests", dependencies: ["CompatCore"], path: "Tests/CompatCoreTests"),
    ]
)
