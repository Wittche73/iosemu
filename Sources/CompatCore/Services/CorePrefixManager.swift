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
        let prefixURL = configuration.prefixesRoot.appendingPathComponent(gameID.uuidString)
        try fileSystem.createDirectory(at: prefixURL)
        try fileSystem.createDirectory(at: prefixURL.appendingPathComponent("drive_c"))
        try fileSystem.createDirectory(at: prefixURL.appendingPathComponent("dosdevices"))
        return prefixURL
    }

    nonisolated public func prefixURL(for game: GameRecord) -> URL {
        configuration.prefixesRoot.appendingPathComponent(game.prefixRelativePath)
    }
}
