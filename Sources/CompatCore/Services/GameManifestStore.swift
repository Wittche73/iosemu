import Foundation

public protocol GameManifestStoring: Sendable {
    func loadGames() async throws -> [GameRecord]
    func upsert(_ game: GameRecord) async throws
    func game(id: UUID) async throws -> GameRecord?
    func delete(id: UUID) async throws
}

public actor GameManifestStore: GameManifestStoring {
    private let manifestURL: URL
    private let fileSystem: FileSystemProviding
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(manifestURL: URL, fileSystem: FileSystemProviding) {
        self.manifestURL = manifestURL
        self.fileSystem = fileSystem
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func loadGames() async throws -> [GameRecord] {
        guard fileSystem.fileExists(at: manifestURL) else { return [] }
        let data = try fileSystem.readData(at: manifestURL)
        return try decoder.decode([GameRecord].self, from: data).sorted { $0.createdAt < $1.createdAt }
    }

    public func upsert(_ game: GameRecord) async throws {
        var games = try await loadGames()
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games[index] = game
        } else {
            games.append(game)
        }
        try persist(games)
    }

    public func game(id: UUID) async throws -> GameRecord? {
        (try await loadGames()).first(where: { $0.id == id })
    }

    public func delete(id: UUID) async throws {
        try persist(try await loadGames().filter { $0.id != id })
    }

    private func persist(_ games: [GameRecord]) throws {
        try fileSystem.writeData(try encoder.encode(games), to: manifestURL)
    }
}
