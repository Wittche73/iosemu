import Foundation

public protocol GameImporting: Sendable {
    func importGame(from sourceURL: URL, suggestedName: String?) async throws -> GameRecord
}

public enum ImportError: Error, LocalizedError {
    case executableNotFound

    public var errorDescription: String? {
        "No Windows executable was found in the imported content."
    }
}

public actor GameImportService: GameImporting {
    private let configuration: RuntimeConfiguration
    private let fileSystem: FileSystemProviding
    private let store: GameManifestStoring
    private let prefixManager: PrefixManaging

    public init(
        configuration: RuntimeConfiguration,
        fileSystem: FileSystemProviding,
        store: GameManifestStoring,
        prefixManager: PrefixManaging
    ) {
        self.configuration = configuration
        self.fileSystem = fileSystem
        self.store = store
        self.prefixManager = prefixManager
    }

    public func importGame(from sourceURL: URL, suggestedName: String?) async throws -> GameRecord {
        try fileSystem.createDirectory(at: configuration.gamesRoot)
        let gameID = UUID()
        let gameFolder = configuration.gamesRoot.appending(path: gameID.uuidString, directoryHint: .isDirectory)
        try fileSystem.createDirectory(at: gameFolder)

        if fileSystem.isDirectory(at: sourceURL) {
            try fileSystem.removeItem(at: gameFolder)
            try fileSystem.copyItem(at: sourceURL, to: gameFolder)
        } else {
            try fileSystem.copyItem(at: sourceURL, to: gameFolder.appending(path: sourceURL.lastPathComponent))
        }

        let files = try fileSystem.enumeratedFiles(at: gameFolder)
        guard let executable = files.first(where: { $0.pathExtension.lowercased() == "exe" }) else {
            throw ImportError.executableNotFound
        }

        let prefixURL = try await prefixManager.createPrefix(for: gameID)
        let relativePath = String(executable.path.dropFirst(gameFolder.path.count + 1))
        let game = GameRecord(
            id: gameID,
            displayName: suggestedName ?? executable.deletingPathExtension().lastPathComponent,
            executableName: executable.lastPathComponent,
            executableRelativePath: relativePath,
            installDirectoryBookmark: gameFolder.path,
            prefixRelativePath: prefixURL.lastPathComponent,
            rendererMode: configuration.defaultRenderer
        )

        try await store.upsert(game)
        return game
    }
}
