import Foundation

public struct VirtualButtonBinding: Codable, Hashable, Sendable {
    public let identifier: String
    public let normalizedX: Double
    public let normalizedY: Double
    public let action: String

    public init(identifier: String, normalizedX: Double, normalizedY: Double, action: String) {
        self.identifier = identifier
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.action = action
    }
}

public struct InputProfile: Codable, Hashable, Sendable {
    public let gamepadEnabled: Bool
    public let touchOverlayEnabled: Bool
    public let buttons: [VirtualButtonBinding]

    public init(
        gamepadEnabled: Bool = true,
        touchOverlayEnabled: Bool = true,
        buttons: [VirtualButtonBinding] = []
    ) {
        self.gamepadEnabled = gamepadEnabled
        self.touchOverlayEnabled = touchOverlayEnabled
        self.buttons = buttons
    }

    public static let `default` = InputProfile(
        buttons: [
            VirtualButtonBinding(identifier: "left-stick", normalizedX: 0.18, normalizedY: 0.72, action: "move"),
            VirtualButtonBinding(identifier: "a", normalizedX: 0.82, normalizedY: 0.70, action: "confirm"),
            VirtualButtonBinding(identifier: "b", normalizedX: 0.90, normalizedY: 0.60, action: "cancel"),
        ]
    )
}
