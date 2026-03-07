import Foundation

public protocol PrefixManaging: Sendable {
    func createPrefix(for gameID: UUID) async throws -> URL
    func prefixURL(for game: GameRecord) -> URL
}

public actor CorePrefixManager: PrefixManaging {
    private let configuration: RuntimeConfiguration
    private let fileSystem: FileSystemProviding

    public init(configuration: RuntimeConfiguration, fileSystem: FileSystemProviding) {
        self.configuration = configuration
        self.fileSystem = fileSystem
    }

    public func createPrefix(for gameID: UUID) async throws -> URL {
        try fileSystem.createDirectory(at: configuration.prefixesRoot)
        let prefixURL = configuration.prefixesRoot.appending(path: gameID.uuidString, directoryHint: .isDirectory)
        try fileSystem.createDirectory(at: prefixURL)
        try fileSystem.createDirectory(at: prefixURL.appending(path: "drive_c", directoryHint: .isDirectory))
        try fileSystem.createDirectory(at: prefixURL.appending(path: "dosdevices", directoryHint: .isDirectory))
        return prefixURL
    }

    public func prefixURL(for game: GameRecord) -> URL {
        configuration.prefixesRoot.appending(path: game.prefixRelativePath, directoryHint: .isDirectory)
    }
}
