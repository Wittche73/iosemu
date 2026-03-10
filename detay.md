🛠 LocalCompat: Simülatörden Emülatöre Geçiş Rehberi
Bu rehber, projenin mantıksal katmanlarını gerçek Box64 ve Wine motoruyla birleştirmek için gereken Ubuntu tabanlı adımları içerir.

1. Gereksinimlerin Kurulması (Ubuntu)
Öncelikle iOS için çapraz derleme (cross-compilation) yapabilecek araçları sisteme yükleyelim:

```bash
sudo apt update
sudo apt install -y git cmake clang lld llvm make python3 perl
```

2. Box64 "Native" Derleme Süreci
Sahte loglar yerine gerçek x86_64 komutlarını çevirecek statik kütüphaneyi (.a) oluşturalım.

**Adımlar:**
- **Kaynak Kodu:** `git clone https://github.com/ptitSeb/box64.git`
- **Derleme Betiği:** `box64` dizini içinde bir `cross_compile_ios.sh` oluştur ve şunları ekle:

```bash
mkdir build-ios && cd build-ios
cmake .. \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DARM64=1 \
  -DNO_X11=1 \
  -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```
- **Sonuç:** Çıkan `libbox64.a` dosyasını projenin `Frameworks/` klasörüne taşı.

3. C++ Köprüsü (Bridge) Güncellemesi
`RuntimeBridge.cpp` dosyanın içindeki sahte fonksiyonları gerçek Box64 giriş noktalarına (entry points) bağla.

```cpp
#include "box64context.h"

// Eski simülasyon kodu yerine:
extern "C" int start_native_engine(int argc, const char** argv) {
    // 1. JIT Korunmasını Kaldır (iOS W^X Bypass)
    pthread_jit_write_protect_np(false);
    
    // 2. Box64 Context Başlat
    box64context_t *context = NewBox64Context(argc);
    
    // 3. Wine Binary'sini Yükle ve Çalıştır
    int result = RunBox64(context, argv);
    
    return result;
}
```

4. Wine Payload Paketleme
Gerçek Wine binary'lerini (x86_64) IPA'nın içine gömmen gerekiyor.

**Dizin Yapısı:**
```text
LocalCompat.app/
└── Payload/
    └── wine/
        ├── bin/wine (x86_64 binary)
        └── lib/ (DLL ve .so dosyaları)
```
**Kritik:** `RuntimeLauncher.swift` içinde `PATH` ve `LD_LIBRARY_PATH` değişkenlerini bu iç dizine yönlendir.

5. JIT ve Bellek Yönetimi (W^X Bypass)
iOS'in katı güvenlik politikaları gereği, bir bellek sayfası aynı anda hem yazılabilir hem de çalıştırılabilir (Write XOR Execute) olamaz.

- **Entitlements:** Uygulamanın `dynamic-codesigning` yetkisine sahip olması gerekir (JitStreamer veya SideStore/AltStore ile).
- **Kodlama:** `pthread_jit_write_protect_np(false)` ile yazma moduna geçilir, kod üretilir, ardından `true` ile çalıştırma moduna dönülür.

6. Grafik Pipeline: DXVK & MoltenVK Entegrasyonu
DirectX oyunlarını çalıştırmak için şu zinciri kurmalısın:
- **DXVK:** D3D11/10/9 çağrılarını Vulkan'a çevirir.
- **MoltenVK:** Vulkan'ı iOS'in anladığı Metal diline çevirir.
- **MetalFX:** Çözünürlüğü yapay zeka ile yükselterek FPS artışı sağlar.

7. Dosya Sistemi ve Sandbox (Mounting)
iOS her uygulamayı kendi klasörüne (Sandbox) hapseder. 
- `PrefixManager` ile sanal bir `C:` sürücüsü oluşturulur.
- Wine'ın `dosdevices` klasörü üzerinden iOS'teki `Documents` klasörü, Windows'a `D:` sürücüsü olarak gösterilir.

8. Theos ile Nihai Derleme (Makefile)
Ubuntu'daki Theos kurulumun için örnek Makefile yapılandırması:

```makefile
TARGET := iphone:clang:latest:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = LocalCompat

# Swift ve C++ dosyalarını bağla
LocalCompat_FILES = $(wildcard Sources/*.swift) Sources/CBridge/RuntimeBridge.cpp
LocalCompat_LDFLAGS = -L./Frameworks -lbox64 -lmoltenvk
LocalCompat_FRAMEWORKS = UIKit SwiftUI Metal GameController

include $(THEOS_MAKE_PATH)/application.mk
```

9. Hata Ayıklama (Debug) Stratejileri
Emülatör çöktüğünde sorunu anlamak için:
- **BOX64_LOG=1:** Box64'ün çeviri loglarını izle.
- **WINEDEBUG=+all:** Wine'ın Windows API çağrılarını takip et.
- **Socat/Netcat:** Uygulama içindeki logları Wi-Fi üzerinden Ubuntu terminaline aktar.

---
*Not: Bu rehber sürekli güncellenmektedir. Bir sonraki adım, gerçek bir .exe dosyasını ilk kez tetiklemek olacaktır.*