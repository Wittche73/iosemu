import Foundation

public enum LaunchResult: String, Codable, Sendable {
    case neverLaunched
    case running
    case stopped
    case failed
}
