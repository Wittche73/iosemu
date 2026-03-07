import Foundation

public protocol JITAvailabilityChecking: Sendable {
    func isJITAvailable() async -> Bool
}

public struct EnvironmentJITChecker: JITAvailabilityChecking {
    public init() {}

    public func isJITAvailable() async -> Bool {
        ProcessInfo.processInfo.environment["LOCALCOMPAT_JIT_ENABLED"] == "1"
    }
}
