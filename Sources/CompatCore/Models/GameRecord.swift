import Foundation

public enum RendererMode: String, Codable, CaseIterable, Sendable {
    case sdl
    case openGL
    case directXBridge

    public var displayName: String {
        switch self {
        case .sdl: return "SDL"
        case .openGL: return "OpenGL"
        case .directXBridge: return "DX Bridge"
        }
    }
}

public struct GameRecord: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var displayName: String
    public var executableName: String
    public var executableRelativePath: String
    public var installDirectoryBookmark: String
    public var prefixRelativePath: String
    public var rendererMode: RendererMode
    public var inputProfile: InputProfile
    public var lastResult: LaunchResult
    public var lastLaunchedAt: Date?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        displayName: String,
        executableName: String,
        executableRelativePath: String,
        installDirectoryBookmark: String,
        prefixRelativePath: String,
        rendererMode: RendererMode = .sdl,
        inputProfile: InputProfile = .default,
        lastResult: LaunchResult = .neverLaunched,
        lastLaunchedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.executableName = executableName
        self.executableRelativePath = executableRelativePath
        self.installDirectoryBookmark = installDirectoryBookmark
        self.prefixRelativePath = prefixRelativePath
        self.rendererMode = rendererMode
        self.inputProfile = inputProfile
        self.lastResult = lastResult
        self.lastLaunchedAt = lastLaunchedAt
        self.createdAt = createdAt
    }
}
