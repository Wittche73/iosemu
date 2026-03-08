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
    
    /// Fare hareketini C++ katmanına iletir (Göreceli - Delta)
    func handleMouseRelativeMove(dx: Int, dy: Int) {
        if dx != 0 || dy != 0 {
            // print("--- InputManager: Fare Delta -> dX: \(dx), dY: \(dy) ---")
            send_mouse_relative_move(Int32(dx), Int32(dy))
        }
    }
    
    /// Joystick eksen hareketini C++ katmanına iletir
    func handleJoystickAxis(axis: Int, value: Float) {
        // print("--- InputManager: Joystick Ekseni -> Axis: \(axis), Value: \(value) ---")
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
                // 1. Analog Çubuklar (Axis)
                if element == gamepad.leftThumbstick {
                    self.handleJoystickAxis(axis: 0, value: gamepad.leftThumbstick.xAxis.value)
                    self.handleJoystickAxis(axis: 1, value: gamepad.leftThumbstick.yAxis.value)
                } else if element == gamepad.rightThumbstick {
                    self.handleJoystickAxis(axis: 2, value: gamepad.rightThumbstick.xAxis.value)
                    self.handleJoystickAxis(axis: 3, value: gamepad.rightThumbstick.yAxis.value)
                }
                
                // 2. Butonlar (Win32 Virtual Key Codes)
                if element == gamepad.buttonA {
                    self.handleKeyPress(keyCode: VirtualKeys.VK_SPACE, isPressed: gamepad.buttonA.isPressed)
                } else if element == gamepad.buttonB {
                    self.handleKeyPress(keyCode: VirtualKeys.VK_ESCAPE, isPressed: gamepad.buttonB.isPressed)
                } else if element == gamepad.buttonX {
                    self.handleKeyPress(keyCode: 0x52, isPressed: gamepad.buttonX.isPressed) // 'R' Key
                } else if element == gamepad.buttonY {
                    self.handleKeyPress(keyCode: 0x46, isPressed: gamepad.buttonY.isPressed) // 'F' Key
                }
                
                // 3. Tetikler ve Omuz Tuşları
                if element == gamepad.leftShoulder {
                    self.handleKeyPress(keyCode: 0x11, isPressed: gamepad.leftShoulder.isPressed) // VK_CONTROL
                } else if element == gamepad.rightShoulder {
                    self.handleKeyPress(keyCode: 0x12, isPressed: gamepad.rightShoulder.isPressed) // VK_MENU (ALT)
                }
            }
        }
    }
    #endif
    
    /// Sanal klavye tuş kodları (Win32 VK Codes)
    enum VirtualKeys {
        static let VK_UP = 0x26
        static let VK_DOWN = 0x28
        static let VK_LEFT = 0x25
        static let VK_RIGHT = 0x27
        static let VK_SPACE = 0x20
        static let VK_RETURN = 0x0D
        static let VK_ESCAPE = 0x1B
        static let VK_CONTROL = 0x11
        static let VK_MENU = 0x12 // ALT
    }
}
