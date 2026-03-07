import Foundation
#if os(iOS)
import GameController
#endif

/// Dokunmatik ve Harici Gamepad (MFi) girdilerini Win32 olaylarına çeviren sınıf
class InputManager {
    static let shared = InputManager()
    
    private init() {
        #if os(iOS)
        setupGamepadMonitoring()
        #endif
    }
    
    /// Bir tuş basımı olayını C++ katmanına iletir
    func handleKeyPress(keyCode: Int, isPressed: Bool) {
        print("--- InputManager: Tuş Olayı -> Code: \(keyCode), Pressed: \(isPressed) ---")
        send_key_event(Int32(keyCode), isPressed)
    }
    
    /// Fare hareketini C++ katmanına iletir
    func handleMouseMove(x: Int, y: Int) {
        print("--- InputManager: Fare Hareketi -> X: \(x), Y: \(y) ---")
        send_mouse_move(Int32(x), Int32(y))
    }
    
    /// Joystick eksen hareketini C++ katmanına iletir
    func handleJoystickAxis(axis: Int, value: Float) {
        print("--- InputManager: Joystick Ekseni -> Axis: \(axis), Value: \(value) ---")
        send_joystick_axis(Int32(axis), value)
    }
    
    #if os(iOS)
    private func setupGamepadMonitoring() {
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { _ in
            print("🎮 Gamepad bağlandı!")
            self.configureControllers()
        }
    }
    
    private func configureControllers() {
        for controller in GCController.controllers() {
            controller.extendedGamepad?.valueChangedHandler = { (gamepad, element) in
                // Örnek: Sol analog çubuk
                if element == gamepad.leftThumbstick {
                    self.handleJoystickAxis(axis: 0, value: gamepad.leftThumbstick.xAxis.value)
                    self.handleJoystickAxis(axis: 1, value: gamepad.leftThumbstick.yAxis.value)
                }
            }
        }
    }
    #endif
    
    /// Sanal klavye tuş kodları (Örnekler)
    enum VirtualKeys {
        static let VK_UP = 0x26
        static let VK_DOWN = 0x28
        static let VK_LEFT = 0x25
        static let VK_RIGHT = 0x27
        static let VK_SPACE = 0x20
        static let VK_RETURN = 0x0D
    }
}
