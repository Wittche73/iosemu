import Foundation

public struct RuntimeConfiguration: Codable, Hashable, Sendable {
    public let gamesRoot: URL
    public let prefixesRoot: URL
    public let logsRoot: URL
    public let jitRequired: Bool
    public let defaultRenderer: RendererMode

    public init(
        gamesRoot: URL,
        prefixesRoot: URL,
        logsRoot: URL,
        jitRequired: Bool = true,
        defaultRenderer: RendererMode = .sdl
    ) {
        self.gamesRoot = gamesRoot
        self.prefixesRoot = prefixesRoot
        self.logsRoot = logsRoot
        self.jitRequired = jitRequired
        self.defaultRenderer = defaultRenderer
    }
}
