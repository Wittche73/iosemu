import CompatCore
import Foundation
import XCTest

final class CompatCoreTests: XCTestCase {
    func testManifestStorePersistsGames() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let fs = LocalFileSystem()
        let store = GameManifestStore(manifestURL: root.appending(path: "games.json"), fileSystem: fs)
        let game = GameRecord(
            displayName: "Test",
            executableName: "game.exe",
            executableRelativePath: "game.exe",
            installDirectoryBookmark: root.path,
            prefixRelativePath: "prefix"
        )

        try await store.upsert(game)
        let loaded = try await store.loadGames()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.displayName, "Test")
    }

    func testRuntimeHostRejectsLaunchWithoutJIT() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let fs = LocalFileSystem()
        let config = RuntimeConfiguration(
            gamesRoot: root.appending(path: "Games", directoryHint: .isDirectory),
            prefixesRoot: root.appending(path: "Prefixes", directoryHint: .isDirectory),
            logsRoot: root.appending(path: "Logs", directoryHint: .isDirectory)
        )
        let store = GameManifestStore(manifestURL: root.appending(path: "games.json"), fileSystem: fs)
        let prefixManager = PrefixManager(configuration: config, fileSystem: fs)
        let importer = GameImportService(configuration: config, fileSystem: fs, store: store, prefixManager: prefixManager)
        let host = RuntimeHost(
            configuration: config,
            store: store,
            importer: importer,
            prefixManager: prefixManager,
            runtimeBridge: StubRuntimeBridge(),
            jitChecker: DisabledJITChecker(),
            fileSystem: fs
        )
        let installRoot = config.gamesRoot.appending(path: "demo", directoryHint: .isDirectory)
        try fs.createDirectory(at: installRoot)
        try fs.writeData(Data(), to: installRoot.appending(path: "demo.exe"))
        let game = GameRecord(
            displayName: "Demo",
            executableName: "demo.exe",
            executableRelativePath: "demo.exe",
            installDirectoryBookmark: installRoot.path,
            prefixRelativePath: "demo"
        )
        try await store.upsert(game)

        do {
            try await host.launchGame(id: game.id)
            XCTFail("Expected JIT gate to block launch.")
        } catch let error as RuntimeHostError {
            XCTAssertEqual(error.errorDescription, RuntimeHostError.jitRequired.errorDescription)
        }
    }

    func testRuntimeHostWritesLaunchLog() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let fs = LocalFileSystem()
        let config = RuntimeConfiguration(
            gamesRoot: root.appending(path: "Games", directoryHint: .isDirectory),
            prefixesRoot: root.appending(path: "Prefixes", directoryHint: .isDirectory),
            logsRoot: root.appending(path: "Logs", directoryHint: .isDirectory)
        )
        let store = GameManifestStore(manifestURL: root.appending(path: "games.json"), fileSystem: fs)
        let prefixManager = PrefixManager(configuration: config, fileSystem: fs)
        let importer = GameImportService(configuration: config, fileSystem: fs, store: store, prefixManager: prefixManager)
        let host = RuntimeHost(
            configuration: config,
            store: store,
            importer: importer,
            prefixManager: prefixManager,
            runtimeBridge: StubRuntimeBridge(),
            jitChecker: EnabledJITChecker(),
            fileSystem: fs
        )
        let installRoot = config.gamesRoot.appending(path: "demo", directoryHint: .isDirectory)
        try fs.createDirectory(at: installRoot)
        try fs.writeData(Data(), to: installRoot.appending(path: "demo.exe"))
        let game = GameRecord(
            displayName: "Demo",
            executableName: "demo.exe",
            executableRelativePath: "demo.exe",
            installDirectoryBookmark: installRoot.path,
            prefixRelativePath: "demo"
        )
        try await store.upsert(game)

        try await host.launchGame(id: game.id)
        let logs = try await host.fetchLogs(for: game.id)

        XCTAssertTrue(logs.contains("launch_stub"))
    }
}

private struct DisabledJITChecker: JITAvailabilityChecking {
    func isJITAvailable() async -> Bool { false }
}

private struct EnabledJITChecker: JITAvailabilityChecking {
    func isJITAvailable() async -> Bool { true }
}
