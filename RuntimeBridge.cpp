#include "RuntimeBridge.h"
#include <iostream>
#include <string>
#include <dlfcn.h>
#include <thread>

// XeniOS Core Subsystems
#include "Core/CPU/XenonJitBackend.h"
#include "Core/CPU/JITCacheManager.h"
#include "Core/GPU/XenosMetalRenderer.h"
#include "Core/GPU/ShaderWarmingService.h"
#include "Core/Memory/XboxMemory.h"
#include "Core/Memory/MemoryOptimizer.h"
#include "Core/Kernel/XboxKernel.h"
#include "Core/Kernel/ThreadScheduler.h"
#include "Core/Kernel/SyscallBridge.h"
#include "Core/VFS/XboxFileSystem.h"
#include "Core/APU/AudioSystem.h"
#include "Core/HID/XInputManager.h"
#ifdef __APPLE__
#include <crt_externs.h>
#include <pthread.h>
#include <sys/mman.h>
#define GET_ENVIRON() (*_NSGetEnviron())

// Function pointer for JIT toggle
typedef void (*jit_protect_func)(int);
#else
extern char** environ;
#define GET_ENVIRON() environ
#endif

// Emulator state
static std::string last_error = "None";
static void* box64_handle = nullptr;
static void* fex_handle = nullptr;
static std::string stats_buffer = "{}";
static int current_engine = 0; // 0: Box64, 1: FEX-Emu, 2: XeniOS

// Global XeniOS Subsystems
static XeniOS::Memory::XboxMemory* g_xboxMemory = nullptr;
static XeniOS::Kernel::XboxKernel* g_xboxKernel = nullptr;
static XeniOS::VFS::XboxFileSystem* g_xboxVfs = nullptr;
static XeniOS::GPU::XenosMetalRenderer* g_xenosGpu = nullptr;
static XeniOS::APU::AudioSystem* g_xboxAudio = nullptr;
static XeniOS::HID::XInputManager* g_xboxInput = nullptr;

// New optimized subsystems
static XeniOS::CPU::JITCacheManager* g_jitCache = nullptr;
static XeniOS::Memory::MemoryOptimizer* g_memOptimizer = nullptr;
static XeniOS::Kernel::ThreadScheduler* g_threadScheduler = nullptr;
static XeniOS::Kernel::SyscallBridge* g_syscallBridge = nullptr;

// Prototypeler
typedef int (*emulator_main_func)(int argc, const char** argv, char** env);
typedef void (*box64_flush_cache_func)();
typedef void (*box64_get_stats_func)(uint64_t* hits, uint64_t* misses, uint32_t* cache_use);

extern "C" void set_engine(int engine) {
    current_engine = engine;
    std::cout << "[Emulator Bridge] Engine set to: " << (engine == 0 ? "Box64" : (engine == 1 ? "FEX-Emu" : "XeniOS/Xbox360")) << std::endl;
}

extern "C" bool init_runtime() {
    std::cout << "[Emulator Bridge] Initializing native engine..." << std::endl;
    
    if (current_engine == 2) {
        std::cout << "[Emulator Bridge] Booting XeniOS Xbox 360 Core..." << std::endl;
        
        g_xboxMemory = new XeniOS::Memory::XboxMemory();
        g_xboxKernel = new XeniOS::Kernel::XboxKernel();
        g_xboxVfs = new XeniOS::VFS::XboxFileSystem();
        g_xenosGpu = new XeniOS::GPU::XenosMetalRenderer();
        g_xboxAudio = new XeniOS::APU::AudioSystem();
        g_xboxInput = new XeniOS::HID::XInputManager();

        // Initialize the memory subsystem
        if (!g_xboxMemory->Initialize()) {
            last_error = "Failed to initialize Xbox 360 Memory subsystem";
            std::cerr << "[Emulator Bridge] " << last_error << std::endl;
            return false;
        }

        // Initialize kernel
        if (!g_xboxKernel->InitializeOS()) {
            last_error = "Failed to initialize XeniOS Kernel subsystem";
            std::cerr << "[Emulator Bridge] " << last_error << std::endl;
            return false;
        }

        // Initialize new optimization subsystems
        g_jitCache = new XeniOS::CPU::JITCacheManager();
        g_jitCache->Initialize("/var/mobile/Documents/JITCache");

        g_memOptimizer = new XeniOS::Memory::MemoryOptimizer();
        g_memOptimizer->Initialize(1024 * 1024 * 1024); // 1GB budget

        g_threadScheduler = new XeniOS::Kernel::ThreadScheduler();
        g_threadScheduler->Initialize();

        g_syscallBridge = new XeniOS::Kernel::SyscallBridge();
        g_syscallBridge->Initialize("/var/mobile/Documents/wineprefix");

        std::cout << "[Emulator Bridge] XeniOS Subsystems + Optimizers Initialized." << std::endl;
        return true;
    }

    const char* lib_name = (current_engine == 0) ? "libbox64.dylib" : "libFEXCore.dylib";
    void** handle_ptr = (current_engine == 0) ? &box64_handle : &fex_handle;

    *handle_ptr = dlopen(lib_name, RTLD_NOW | RTLD_GLOBAL);
    if (!*handle_ptr) {
        std::string framework_path = "@executable_path/Frameworks/" + std::string(lib_name);
        *handle_ptr = dlopen(framework_path.c_str(), RTLD_NOW | RTLD_GLOBAL);
    }
    
    if (*handle_ptr) {
        std::cout << "[Emulator Bridge] Native engine library (" << (current_engine == 0 ? "Box64" : "FEX-Emu") << ") loaded successfully." << std::endl;
        return true;
    } else {
        const char* err = dlerror();
        last_error = err ? err : "Failed to load emulator library";
        std::cerr << "[Emulator Bridge] CRITICAL ERROR: " << last_error << std::endl;
        return false;
    }
}

extern "C" bool init_graphics() {
    std::cout << "[Emulator Bridge] Graphics initialized (MoltenVK -> Metal)" << std::endl;
    return true;
}

extern "C" void enable_metalfx(int mode) {
    printf("[Emulator Bridge] MetalFX Mode requested: %d\n", mode);
    // 0: Off, 1: Spatial, 2: Temporal
    if (mode == 1) {
        setenv("MVK_CONFIG_USE_METALFX", "1", 1);
        setenv("MVK_CONFIG_METALFX_TYPE", "spatial", 1);
    } else if (mode == 2) {
        setenv("MVK_CONFIG_USE_METALFX", "1", 1);
        setenv("MVK_CONFIG_METALFX_TYPE", "temporal", 1);
    } else {
        setenv("MVK_CONFIG_USE_METALFX", "0", 1);
    }
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
    if (current_engine == 2) {
        // XeniOS (Xbox 360) Execution Path
        printf("[Emulator Bridge] Booting XeniOS Core for: %s\n", exe_path.c_str());
        
        XeniOS::CPU::XenonJitBackend cpuBackend;
        if (!cpuBackend.Initialize()) {
            std::cerr << "[Emulator Bridge] CRITICAL: Failed to initialize Xenon CPU JIT." << std::endl;
            return;
        }

        // Mount the game directory
        if (g_xboxVfs) {
            g_xboxVfs->MountSymbolicLink("game:", exe_path);
        }

        // Execute from Xbox 360 default entry point
        cpuBackend.Execute(0x82000000);
        return;
    }

    // Box64 / FEX Execution Path
    void* handle = (current_engine == 0) ? box64_handle : fex_handle;
    const char* engine_name = (current_engine == 0) ? "box64" : "FEXInterpreter";

    if (!handle) {
        std::cerr << "[Emulator Bridge] Aborting: Engine library not loaded." << std::endl;
        return;
    }

    emulator_main_func emu_main = (emulator_main_func)dlsym(handle, (current_engine == 0) ? "box64_main" : "FEX_main");
    if (!emu_main) emu_main = (emulator_main_func)dlsym(handle, "main");

    if (emu_main) {
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
        if (current_engine == 0) {
            setenv("BOX64_LOG", "3", 1);
            setenv("BOX64_DYNAREC", "1", 1);
            setenv("BOX64_NOBANNER", "0", 1);
            setenv("BOX64_NOENVFILES", "1", 1);
            setenv("BOX64_SYSINFO_CACHED", "1", 1);
            setenv("BOX64_SYSINFO_NCPU", "8", 1);
        } else {
            setenv("FEX_LOGLEVEL", "1", 1);
            setenv("FEX_TSO", "1", 1);
        }

        const char* argv[] = { engine_name, wine_binary.c_str(), exe_path.c_str(), nullptr };
        
        char* custom_env[] = { 
            (char*)(current_engine == 0 ? "BOX64_LOG=1" : "FEX_LOGLEVEL=1"), 
            (char*)"LC_ALL=C",
            (char*)NULL 
        };
        
        printf("[Emulator Bridge] Calling %s Entry Point...\n", engine_name);
        fflush(stdout);

        // 1. JIT Korunmasını Kaldır (iOS W^X Bypass)
#ifdef __APPLE__
        jit_protect_func jit_toggle = (jit_protect_func)dlsym(RTLD_DEFAULT, "pthread_jit_write_protect_np");
        if (jit_toggle) jit_toggle(0);
#endif

        int result = emu_main(3, (const char**)argv, custom_env);

        // 2. JIT Korunmasını Geri Getir
#ifdef __APPLE__
        if (jit_toggle) jit_toggle(1);
#endif

        printf("[Emulator Bridge] %s exited with code: %d\n", engine_name, result);
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
