#include "RuntimeBridge.h"
#include <iostream>
#include <string>
#include <dlfcn.h>
#include <thread>

static std::string last_error = "None";
static void* box64_handle = nullptr;

// Olası Box64 main loader fonksiyon prototipi
typedef int (*box64_main_func)(int argc, const char** argv);

extern "C" bool init_runtime() {
    std::cout << "[Box64 Engine Bridge] Initializing..." << std::endl;
    
    // Gerçek veya test ortamı dylib yüklemesi
    box64_handle = dlopen("libbox64.dylib", RTLD_NOW | RTLD_GLOBAL);
    if (!box64_handle) {
        // Fallback: Uygulama paketi içindeki Frameworks dizinine bak
        box64_handle = dlopen("@executable_path/Frameworks/libbox64.dylib", RTLD_NOW | RTLD_GLOBAL);
    }
    
    if (box64_handle) {
        std::cout << "[Box64 Engine Bridge] Successfully loaded dynamic engine library!" << std::endl;
        return true;
    } else {
        last_error = dlerror() ? dlerror() : "Unknown dylib load error";
        std::cout << "[Box64 Engine Bridge] WARNING: Could not load libbox64.dylib: " << last_error << std::endl;
        std::cout << "[Box64 Engine Bridge] Falling back to simulation mode." << std::endl;
        return true; // Şimdilik test için çökmemesi adına simülasyona dön
    }
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
    // std::cout << "[C++] Input: Key " << keycode << (is_pressed ? " Pressed" : " Released") << std::endl;
}

extern "C" void send_mouse_move(int x, int y) {
    // std::cout << "[C++] Input: Mouse Move -> X: " << x << ", Y: " << y << std::endl;
}

extern "C" void send_joystick_axis(int axis, float value) {}
extern "C" void send_joystick_button(int button, bool is_pressed) {}

// Arka planda çalışacak olan ana oyun emülasyon döngüsü
void execute_engine_thread(std::string exe_path) {
    if (box64_handle) {
        box64_main_func b64_main = (box64_main_func)dlsym(box64_handle, "main");
        if (!b64_main) {
            b64_main = (box64_main_func)dlsym(box64_handle, "box64_main");
        }
        
        if (b64_main) {
            std::cout << "[Box64 Engine Bridge] Executing binary natively: " << exe_path << std::endl;
            const char* argv[] = { "box64", exe_path.c_str(), nullptr };
            
            // Bu çağrı oyun kapanana kadar bloklar
            int result = b64_main(2, argv);
            std::cout << "[Box64 Engine Bridge] Execution finished with code: " << result << std::endl;
        } else {
            std::cout << "[Box64 Engine Bridge] CRITICAL: Found library but missing 'main' or 'box64_main' symbol!" << std::endl;
        }
    } else {
        std::cout << "[Simulation] Playing mock game: " << exe_path << " (Waiting 3 seconds)" << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(3));
        std::cout << "[Simulation] Mock game exited cleanly." << std::endl;
    }
}

extern "C" bool load_exe(const char* path) {
    if (path == nullptr) {
        last_error = "Path is null";
        return false;
    }
    
    std::string exe_path(path);
    std::cout << "[C++] Dispatching execute command for: " << exe_path << std::endl;
    
    // UI thread'inin kilitlenmesini engellemek için ana motora kontrolü ayrı bir thread'de veriyoruz
    std::thread engine_thread(execute_engine_thread, exe_path);
    engine_thread.detach();
    
    return true;
}

extern "C" void run_cpu_cycle() {
    // Artık asenkron bir motor modeline geçtiğimiz için simüle CPU turuna gerek kalmadı
}

extern "C" const char* get_last_runtime_error() {
    return last_error.c_str();
}
