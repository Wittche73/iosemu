#ifndef RuntimeBridge_h
#define RuntimeBridge_h

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Emülasyon motorunu başlatır
bool init_runtime(void);

/// Grafik sistemini başlatır (MoltenVK/Vulkan)
bool init_graphics(void);

/// MetalFX Upscaling özelliğini yönetir
void enable_metalfx(int mode);

/// Metal Layer (MTKView) referansını motora iletir
void set_metal_layer(void* layer);

/// Ses sistemini başlatır (OpenAL/SDL)
bool init_audio(void);

/// Klavye olayı gönderir
void send_key_event(int keycode, bool is_pressed);

/// Fare hareketi gönderir (Mutlak)
void send_mouse_move(int x, int y);

/// Fare hareketi gönderir (Göreceli - Delta)
void send_mouse_relative_move(int dx, int dy);

/// Joystick eksen verisi gönderir
void send_joystick_axis(int axis, float value);

/// Joystick buton verisi gönderir
void send_joystick_button(int button, bool is_pressed);

/// Belirtilen yoldaki .exe dosyasını yükler
bool load_exe(const char* path, const char* prefix_path);

/// Bir CPU çevrimi koşturur (Simüle)
void run_cpu_cycle(void);

/// Emülatörden son durum mesajını alır
const char* get_last_runtime_error(void);

/// DynaRec cache'ini acil durumda temizler (Memory Pressure)
void flush_dynarec_cache(void);

/// Motor istatistiklerini JSON formatında döndürür
const char* get_engine_stats(void);

#ifdef __cplusplus
}
#endif

#endif /* RuntimeBridge_h */
