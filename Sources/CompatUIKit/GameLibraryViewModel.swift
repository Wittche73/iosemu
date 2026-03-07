#if canImport(UIKit)

import Foundation

@MainActor
public final class GameLibraryViewModel {
    public let runtimeHost: RuntimeHosting
    public private(set) var games: [GameRecord] = []
    public private(set) var lastErrorMessage: String?

    public init(runtimeHost: RuntimeHosting) {
        self.runtimeHost = runtimeHost
    }

    public func reload() async {
        do {
            games = try await runtimeHost.listGames()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }
}
#endif
