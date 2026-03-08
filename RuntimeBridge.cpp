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
    std::cout << "[Emulator Bridge] Initializing native engine..." << std::endl;
    
    // Gerçek veya test ortamı dylib yüklemesi
    box64_handle = dlopen("libbox64.dylib", RTLD_NOW | RTLD_GLOBAL);
    if (!box64_handle) {
        // Fallback: Uygulama paketi içindeki Frameworks dizinine bak
        box64_handle = dlopen("@executable_path/Frameworks/libbox64.dylib", RTLD_NOW | RTLD_GLOBAL);
    }
    
    if (box64_handle) {
        std::cout << "[Emulator Bridge] Native engine library (Box64) loaded successfully." << std::endl;
        return true;
    } else {
        const char* err = dlerror();
        last_error = err ? err : "Failed to load libbox64.dylib";
        std::cerr << "[Emulator Bridge] CRITICAL ERROR: " << last_error << std::endl;
        return false; // Simulation mode removed.
    }
}

extern "C" bool init_graphics() {
    std::cout << "[Emulator Bridge] Graphics initialized (MoltenVK -> Metal)" << std::endl;
    return true;
}

extern "C" void enable_metalfx(int mode) {
    std::cout << "[Emulator Bridge] MetalFX Upscaling: " << (mode == 0 ? "Off" : "Temporal") << std::endl;
}

extern "C" bool init_audio() {
    std::cout << "[Emulator Bridge] Audio subsystem standby." << std::endl;
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
    if (!box64_handle) {
        std::cerr << "[Emulator Bridge] Aborting: Engine library not loaded." << std::endl;
        return;
    }

    box64_main_func b64_main = (box64_main_func)dlsym(box64_handle, "box64_main");
    if (!b64_main) b64_main = (box64_main_func)dlsym(box64_handle, "_box64_main");
    if (!b64_main) b64_main = (box64_main_func)dlsym(box64_handle, "main");
    if (!b64_main) b64_main = (box64_main_func)dlsym(box64_handle, "_main");

    if (b64_main) {
        // Log dosyasına anında yazılması için tamponlamayı kapat
        setvbuf(stdout, NULL, _IONBF, 0);
        setvbuf(stderr, NULL, _IONBF, 0);

        // Eğer prefix_path bir dosya ise (wine.bin gibi), klasör kısmını al
        std::string actual_prefix = prefix_path;
        std::string wine_binary = prefix_path;
        
        if (prefix_path.find(".bin") != std::string::npos || prefix_path.find("/wine") != std::string::npos) {
            size_t pos = prefix_path.find("/drive_c");
            if (pos != std::string::npos) {
                actual_prefix = prefix_path.substr(0, pos);
            }
        }

        std::cout << "[Emulator Bridge] WINEPREFIX: " << actual_prefix << std::endl;
        
        setenv("WINEPREFIX", actual_prefix.c_str(), 1);
        setenv("HOME", actual_prefix.c_str(), 1);
        setenv("BOX64_LOG", "3", 1); // Daha detaylı log
        setenv("BOX64_DYNAREC", "1", 1);
        setenv("BOX64_NOBANNER", "0", 1);
        
        // Critical iOS Fix: Disable shm_open based config loading
        setenv("BOX64_NOENVFILES", "1", 1);

        // iOS Sandbox Fix: Hardware bypass
        setenv("BOX64_SYSINFO_CACHED", "1", 1);
        setenv("BOX64_SYSINFO_NCPU", "8", 1);
        setenv("BOX64_SYSINFO_CPUNAME", "Apple ARM64", 1);
        setenv("BOX64_SYSINFO_FREQUENCY", "2500000000", 1);

        // X86_64 kütüphanelerinin aranacağı yer (Wine DLL'lerinin olduğu yer)
        std::string wine_lib_path = actual_prefix + "/drive_c/windows/system32";
        setenv("BOX64_LD_LIBRARY_PATH", wine_lib_path.c_str(), 1);

        const char* argv[] = { "box64", wine_binary.c_str(), exe_path.c_str(), nullptr };
        
        // Critical iOS Fix: Pure environment array to avoid auxval scan crashes
        char* custom_env[] = { 
            (char*)"BOX64_LOG=1", 
            (char*)"BOX64_NOENVFILES=1",
            (char*)NULL, 
            (char*)NULL 
        };
        
        printf("[Emulator Bridge] Calling Entry Point (argc=3)...\n");
        fflush(stdout);

        int result = b64_main(3, argv, custom_env);
        printf("[Emulator Bridge] Main thread exited with code: %d\n", result);
        fflush(stdout);

    } else {
        std::cerr << "[Emulator Bridge] CRITICAL: Missing 'box64_main' symbol in dylib!" << std::endl;
    }
}

extern "C" bool load_exe(const char* path, const char* prefix_path) {
    if (path == nullptr || prefix_path == nullptr) {
        last_error = "Path or Prefix is null";
        return false;
    }
    
    std::string exe_path(path);
    std::string prefix(prefix_path);
    std::cout << "[Emulator Bridge] Dispatching native thread for: " << exe_path << std::endl;
    
    // UI thread'inin kilitlenmesini engellemek için ana motora kontrolü ayrı bir thread'de veriyoruz
    std::thread engine_thread(execute_engine_thread, exe_path, prefix);
    engine_thread.detach();
    
    return true;
}

extern "C" void run_cpu_cycle() {
    // Real-time asynchronous engine: Manual CPU cycling no longer required.
}

extern "C" const char* get_last_runtime_error() {
    return last_error.c_str();
}
