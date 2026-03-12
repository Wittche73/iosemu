import Foundation

public enum RuntimeContainerFactory {
    public static func makeDefault(
        rootURL: URL,
        fileSystem: FileSystemProviding = LocalFileSystem(),
        runtimeBridge: RuntimeBridge = RealRuntimeBridge(),
        jitChecker: JITAvailabilityChecking = EnvironmentJITChecker()
    ) -> RuntimeHost {
        let configuration = RuntimeConfiguration(
            gamesRoot: rootURL.appendingPathComponent("Games"),
            prefixesRoot: rootURL.appendingPathComponent("Prefixes"),
            logsRoot: rootURL.appendingPathComponent("Logs")
        )
        let store = GameManifestStore(manifestURL: rootURL.appendingPathComponent("games.json"), fileSystem: fileSystem)
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
