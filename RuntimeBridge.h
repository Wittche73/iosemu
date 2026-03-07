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

/// Ses sistemini başlatır (OpenAL/SDL)
bool init_audio(void);

/// Klavye olayı gönderir
void send_key_event(int keycode, bool is_pressed);

/// Fare hareketi gönderir
void send_mouse_move(int x, int y);

/// Joystick eksen verisi gönderir
void send_joystick_axis(int axis, float value);

/// Joystick buton verisi gönderir
void send_joystick_button(int button, bool is_pressed);

/// Belirtilen yoldaki .exe dosyasını yükler
bool load_exe(const char* path);

/// Bir CPU çevrimi koşturur (Simüle)
void run_cpu_cycle(void);

/// Emülatörden son durum mesajını alır
const char* get_last_runtime_error(void);

#ifdef __cplusplus
}
#endif

#endif /* RuntimeBridge_h */
