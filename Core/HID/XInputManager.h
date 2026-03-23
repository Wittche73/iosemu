#ifndef XINPUT_MANAGER_H
#define XINPUT_MANAGER_H

#include <stdint.h>

namespace XeniOS {
namespace HID {

/**
 * Maps iOS GameController inputs to virtual Xbox 360 states (XInput).
 */
class XInputManager {
public:
    XInputManager();
    ~XInputManager();

    // Sets up controller polling
    bool Initialize();

    // Returns the current gamepad state for a specific user index (0-3)
    bool GetState(uint32_t userIndex, void* pStateStruct);
    
    // Sets vibration motors
    void SetState(uint32_t userIndex, float leftMotor, float rightMotor);

private:
    // Virtual controller connection states
};

} // namespace HID
} // namespace XeniOS

#endif // XINPUT_MANAGER_H
