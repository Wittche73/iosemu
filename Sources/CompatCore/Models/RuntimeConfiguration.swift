import Foundation

public enum EmulatorEngine: String, Codable, Sendable {
    case box64
    case fex
}

public struct RuntimeConfiguration: Codable, Hashable, Sendable {
    public let gamesRoot: URL
    public let prefixesRoot: URL
    public let logsRoot: URL
    public let jitRequired: Bool
    public let defaultRenderer: RendererMode
    public let defaultEngine: EmulatorEngine

    public init(
        gamesRoot: URL,
        prefixesRoot: URL,
        logsRoot: URL,
        jitRequired: Bool = true,
        defaultRenderer: RendererMode = .sdl,
        defaultEngine: EmulatorEngine = .box64
    ) {
        self.gamesRoot = gamesRoot
        self.prefixesRoot = prefixesRoot
        self.logsRoot = logsRoot
        self.jitRequired = jitRequired
        self.defaultRenderer = defaultRenderer
        self.defaultEngine = defaultEngine
    }
}
