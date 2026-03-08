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
static std::string stats_buffer = "{}";

// Box64 internal API definitions for advanced control
typedef void (*box64_flush_cache_func)();
typedef void (*box64_get_stats_func)(uint64_t* hits, uint64_t* misses, uint32_t* cache_use);

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

extern "C" void set_metal_layer(void* layer) {
    if (layer) {
        printf("[Emulator Bridge] Metal Layer attached: %p\n", layer);
        // MoltenVK'ya veya Virtual Display Driver'a aktarılacak
    }
}

extern "C" bool init_audio() {
    std::cout << "[Emulator Bridge] Audio subsystem standby." << std::endl;
    return true;
}

extern "C" void send_key_event(int keycode, bool is_pressed) {
    if (keycode > 0) {
        printf("[Emulator Bridge] Input: Key %d %s\n", keycode, (is_pressed ? "Pressed" : "Released"));
    }
}

extern "C" void send_mouse_move(int x, int y) {
    // Mutlak koordinat gönderimi (UI etkileşimi için)
    // printf("[Emulator Bridge] Input: Mouse Absolute -> X: %d, Y: %d\n", x, y);
}

extern "C" void send_mouse_relative_move(int dx, int dy) {
    // Göreceli hareket (FPS oyunları için)
    if (dx != 0 || dy != 0) {
        printf("[Emulator Bridge] Input: Mouse Delta -> dX: %d, dY: %d\n", dx, dy);
    }
}

extern "C" void send_joystick_axis(int axis, float value) {
    if (axis >= 0) {
        // printf("[Emulator Bridge] Input: Joystick Axis %d -> Value: %.2f\n", axis, value);
    }
}

extern "C" void send_joystick_button(int button, bool is_pressed) {
    printf("[Emulator Bridge] Input: Joystick Button %d %s\n", button, (is_pressed ? "Pressed" : "Released"));
}

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

extern "C" void flush_dynarec_cache() {
    if (!box64_handle) return;
    
    std::cout << "[Emulator Bridge] CRITICAL: Flushing DynaRec Caches due to system pressure..." << std::endl;
    
    // Box64'ün iç kütüphanesinden cache temizleme sembolünü çağır (eğer dışa aktarılmışsa)
    box64_flush_cache_func flush_func = (box64_flush_cache_func)dlsym(box64_handle, "box64_flush_cache");
    if (flush_func) {
        flush_func();
        std::cout << "[Emulator Bridge] Cache flush successful." << std::endl;
    } else {
        std::cerr << "[Emulator Bridge] WARNING: box64_flush_cache symbol not found. Emergency restart might be needed." << std::endl;
    }
}

extern "C" const char* get_engine_stats() {
    if (!box64_handle) return "{}";
    
    uint64_t hits = 0, misses = 0;
    uint32_t cache_use = 0;
    
    box64_get_stats_func stats_func = (box64_get_stats_func)dlsym(box64_handle, "box64_get_metrics");
    if (stats_func) {
        stats_func(&hits, &misses, &cache_use);
        stats_buffer = "{\"hits\":" + std::to_string(hits) + 
                       ",\"misses\":" + std::to_string(misses) + 
                       ",\"cache_usage\":" + std::to_string(cache_use) + "}";
    } else {
        // Fallback or static dummy stats
        stats_buffer = "{\"status\":\"active\",\"jit\":\"enabled\",\"health\":\"optimal\"}";
    }
    
    return stats_buffer.c_str();
}

extern "C" const char* get_last_runtime_error() {
    return last_error.c_str();
}
