import Foundation

public enum RuntimeContainerFactory {
    public static func makeDefault(
        rootURL: URL,
        fileSystem: FileSystemProviding = LocalFileSystem(),
        runtimeBridge: RuntimeBridge = RealRuntimeBridge(),
        jitChecker: JITAvailabilityChecking = EnvironmentJITChecker()
    ) -> RuntimeHost {
        let configuration = RuntimeConfiguration(
            gamesRoot: rootURL.appending(path: "Games", directoryHint: .isDirectory),
            prefixesRoot: rootURL.appending(path: "Prefixes", directoryHint: .isDirectory),
            logsRoot: rootURL.appending(path: "Logs", directoryHint: .isDirectory)
        )
        let store = GameManifestStore(manifestURL: rootURL.appending(path: "games.json"), fileSystem: fileSystem)
        let prefixManager = CorePrefixManager(configuration: configuration, fileSystem: fileSystem)
        let importer = GameImportService(
            configuration: configuration,
            fileSystem: fileSystem,
            store: store,
            prefixManager: prefixManager
        )
        return RuntimeHost(
            configuration: configuration,
            store: store,
            importer: importer,
            prefixManager: prefixManager,
            runtimeBridge: runtimeBridge,
            jitChecker: jitChecker,
            fileSystem: fileSystem
        )
    }
}
