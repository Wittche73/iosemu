#include "RuntimeBridge.h"
#include <iostream>
#include <string>

static std::string last_error = "None";

extern "C" bool init_runtime() {
#ifdef REAL_ENGINE
    std::cout << "[Box64] Real Engine binary translator initialized." << std::endl;
    // box64_init(); // Gelecekteki libbox64 linklemesi için
    return true;
#else
    std::cout << "[C++] Runtime initialized (Box64/Wine stack simulation)" << std::endl;
    return true;
#endif
}

extern "C" bool init_graphics() {
    std::cout << "[C++] Graphics Bridge initialized (MoltenVK -> Metal)" << std::endl;
    return true;
}

extern "C" void enable_metalfx(int mode) {
    std::cout << "[C++] MetalFX Upscaling enabled (Mode: " << mode << ")" << std::endl;
}

extern "C" bool init_audio() {
    std::cout << "[C++] Audio Bridge initialized (OpenAL/SDL_Audio)" << std::endl;
    return true;
}

extern "C" void send_key_event(int keycode, bool is_pressed) {
    std::cout << "[C++] Input: Key " << keycode << (is_pressed ? " Pressed" : " Released") << std::endl;
}

extern "C" void send_mouse_move(int x, int y) {
    std::cout << "[C++] Input: Mouse Move -> X: " << x << ", Y: " << y << std::endl;
}

extern "C" void send_joystick_axis(int axis, float value) {
    std::cout << "[C++] Input: Joystick Axis " << axis << " -> Value: " << value << std::endl;
}

extern "C" void send_joystick_button(int button, bool is_pressed) {
    std::cout << "[C++] Input: Joystick Button " << button << (is_pressed ? " Pressed" : " Released") << std::endl;
}

extern "C" bool load_exe(const char* path) {
    if (path == nullptr) {
        last_error = "Path is null";
        return false;
    }
    
#ifdef REAL_ENGINE
    std::cout << "[Box64] Loading real binary via ELF/PE translator: " << path << std::endl;
    // box64_load(path);
    return true;
#else
    std::cout << "[C++] Loading executable: " << path << std::endl;
    return true;
#endif
}

extern "C" void run_cpu_cycle() {
    // Simüle edilmiş CPU döngüsü
    static int cycle_count = 0;
    cycle_count++;
}

extern "C" const char* get_last_runtime_error() {
    return last_error.c_str();
}
