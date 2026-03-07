import Foundation

public struct RuntimeLaunchContext: Sendable {
    public let executableURL: URL
    public let installDirectoryURL: URL
    public let prefixURL: URL
    public let logsURL: URL
    public let rendererMode: RendererMode
    public let inputProfile: InputProfile

    public init(
        executableURL: URL,
        installDirectoryURL: URL,
        prefixURL: URL,
        logsURL: URL,
        rendererMode: RendererMode,
        inputProfile: InputProfile
    ) {
        self.executableURL = executableURL
        self.installDirectoryURL = installDirectoryURL
        self.prefixURL = prefixURL
        self.logsURL = logsURL
        self.rendererMode = rendererMode
        self.inputProfile = inputProfile
    }
}

public protocol RuntimeBridge: Sendable {
    func launch(context: RuntimeLaunchContext) async throws
    func stop(gameID: UUID) async throws
}

public struct StubRuntimeBridge: RuntimeBridge {
    public init() {}

    public func launch(context: RuntimeLaunchContext) async throws {
        let line = "launch_stub executable=\(context.executableURL.lastPathComponent) renderer=\(context.rendererMode.rawValue)\n"
        try Data(line.utf8).write(to: context.logsURL, options: .atomic)
    }

    public func stop(gameID: UUID) async throws {}
}
