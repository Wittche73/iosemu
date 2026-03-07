import Foundation

public enum RuntimeHostError: Error, LocalizedError {
    case gameNotFound
    case jitRequired

    public var errorDescription: String? {
        switch self {
        case .gameNotFound: return "The selected game could not be found."
        case .jitRequired: return "JIT must be enabled before launching a local compatibility session."
        }
    }
}

public protocol RuntimeHosting: Sendable {
    func importGame(from sourceURL: URL, suggestedName: String?) async throws -> GameRecord
    func createPrefix(for gameID: UUID) async throws -> URL
    func launchGame(id: UUID) async throws
    func stopGame(id: UUID) async throws
    func fetchLogs(for gameID: UUID) async throws -> String
    func updateInputProfile(for gameID: UUID, profile: InputProfile) async throws -> GameRecord
    func listGames() async throws -> [GameRecord]
}

public actor RuntimeHost: RuntimeHosting {
    private let configuration: RuntimeConfiguration
    private let store: GameManifestStoring
    private let importer: GameImporting
    private let prefixManager: PrefixManaging
    private let runtimeBridge: RuntimeBridge
    private let jitChecker: JITAvailabilityChecking
    private let fileSystem: FileSystemProviding

    public init(
        configuration: RuntimeConfiguration,
        store: GameManifestStoring,
        importer: GameImporting,
        prefixManager: PrefixManaging,
        runtimeBridge: RuntimeBridge,
        jitChecker: JITAvailabilityChecking,
        fileSystem: FileSystemProviding
    ) {
        self.configuration = configuration
        self.store = store
        self.importer = importer
        self.prefixManager = prefixManager
        self.runtimeBridge = runtimeBridge
        self.jitChecker = jitChecker
        self.fileSystem = fileSystem
    }

    public func importGame(from sourceURL: URL, suggestedName: String?) async throws -> GameRecord {
        try await importer.importGame(from: sourceURL, suggestedName: suggestedName)
    }

    public func createPrefix(for gameID: UUID) async throws -> URL {
        try await prefixManager.createPrefix(for: gameID)
    }

    public func listGames() async throws -> [GameRecord] {
        try await store.loadGames()
    }

    public func launchGame(id: UUID) async throws {
        guard var game = try await store.game(id: id) else { throw RuntimeHostError.gameNotFound }
        if configuration.jitRequired, await jitChecker.isJITAvailable() == false {
            game.lastResult = .failed
            try await store.upsert(game)
            throw RuntimeHostError.jitRequired
        }

        try fileSystem.createDirectory(at: configuration.logsRoot)
        let installRoot = URL(fileURLWithPath: game.installDirectoryBookmark, isDirectory: true)
        let context = RuntimeLaunchContext(
            executableURL: installRoot.appending(path: game.executableRelativePath),
            installDirectoryURL: installRoot,
            prefixURL: prefixManager.prefixURL(for: game),
            logsURL: configuration.logsRoot.appending(path: "\(game.id.uuidString).log"),
            rendererMode: game.rendererMode,
            inputProfile: game.inputProfile
        )

        try await runtimeBridge.launch(context: context)
        game.lastResult = .running
        game.lastLaunchedAt = Date()
        try await store.upsert(game)
    }

    public func stopGame(id: UUID) async throws {
        guard var game = try await store.game(id: id) else { throw RuntimeHostError.gameNotFound }
        try await runtimeBridge.stop(gameID: id)
        game.lastResult = .stopped
        try await store.upsert(game)
    }

    public func fetchLogs(for gameID: UUID) async throws -> String {
        let logURL = configuration.logsRoot.appending(path: "\(gameID.uuidString).log")
        guard fileSystem.fileExists(at: logURL) else { return "" }
        return String(decoding: try fileSystem.readData(at: logURL), as: UTF8.self)
    }

    public func updateInputProfile(for gameID: UUID, profile: InputProfile) async throws -> GameRecord {
        guard var game = try await store.game(id: gameID) else { throw RuntimeHostError.gameNotFound }
        game.inputProfile = profile
        try await store.upsert(game)
        return game
    }
}
