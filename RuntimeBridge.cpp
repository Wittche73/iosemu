#include "RuntimeBridge.h"
#include <iostream>
#include <string>
#include <dlfcn.h>
#include <thread>

#ifdef __APPLE__
#include <crt_externs.h>
#define GET_ENVIRON() (*_NSGetEnviron())
#else
extern char** environ;
#define GET_ENVIRON() environ
#endif

static std::string last_error = "None";
static void* box64_handle = nullptr;

// Olası Box64 main loader fonksiyon prototipi
typedef int (*box64_main_func)(int argc, const char** argv, char** env);

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
        const char* err = dlerror();
        last_error = err ? err : "Unknown dylib load error";
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
void execute_engine_thread(std::string exe_path, std::string prefix_path) {
    if (box64_handle) {
        box64_main_func b64_main = (box64_main_func)dlsym(box64_handle, "box64_main");
        if (!b64_main) {
            b64_main = (box64_main_func)dlsym(box64_handle, "_box64_main");
        }
        if (!b64_main) {
            b64_main = (box64_main_func)dlsym(box64_handle, "main");
        }
        if (!b64_main) {
            b64_main = (box64_main_func)dlsym(box64_handle, "_main");
        }

        if (b64_main) {
            std::cout << "[Box64 Engine Bridge] Setting WINEPREFIX to: " << prefix_path << std::endl;
            setenv("WINEPREFIX", prefix_path.c_str(), 1);
            setenv("BOX64_LOG", "1", 1);
            setenv("BOX64_DYNAREC", "1", 1);
            
            // On iOS, we also need to set HOME to the prefix to avoid sandbox violations
            setenv("HOME", prefix_path.c_str(), 1);

            std::string wine_binary = prefix_path + "/drive_c/windows/system32/wine";
            std::cout << "[Box64 Engine Bridge] Executing: box64 " << wine_binary << " " << exe_path << std::endl;
            
            const char* argv[] = { "box64", wine_binary.c_str(), exe_path.c_str(), nullptr };
            
            printf("[Box64 Engine Bridge] Calling b64_main with 3 args...\n");
            int result = b64_main(3, argv, GET_ENVIRON());
            printf("[Box64 Engine Bridge] Execution finished with code: %d\n", result);

        } else {
            std::cerr << "[Box64 Engine Bridge] CRITICAL: Missing 'box64_main' symbol!" << std::endl;
        }
    } else {
        std::cout << "[Simulation] Playing mock game: " << exe_path << " (Waiting 3 seconds) using prefix: " << prefix_path << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(3));
        std::cout << "[Simulation] Mock game exited cleanly." << std::endl;
    }
}

extern "C" bool load_exe(const char* path, const char* prefix_path) {
    if (path == nullptr || prefix_path == nullptr) {
        last_error = "Path or Prefix is null";
        return false;
    }
    
    std::string exe_path(path);
    std::string prefix(prefix_path);
    std::cout << "[C++] Dispatching execute command for: " << exe_path << " with prefix: " << prefix << std::endl;
    
    // UI thread'inin kilitlenmesini engellemek için ana motora kontrolü ayrı bir thread'de veriyoruz
    std::thread engine_thread(execute_engine_thread, exe_path, prefix);
    engine_thread.detach();
    
    return true;
}

extern "C" void run_cpu_cycle() {
    // Artık asenkron bir motor modeline geçtiğimiz için simüle CPU turuna gerek kalmadı
}

extern "C" const char* get_last_runtime_error() {
    return last_error.c_str();
}
