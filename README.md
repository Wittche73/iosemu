# LocalCompat — iOS Emülatör Platformu

iOS cihazlarda **Windows (x86/x64)** ve **Xbox 360 (PowerPC)** oyunlarını yerel (native) olarak çalıştırmak için geliştirilmiş kapsamlı bir uyumluluk katmanı.

---

## 🚀 Özellikler

### Windows (x86/x64) Uyumluluk
- **CPU Emülasyonu:** Box64 / FEX-Emu çift motor desteği (runtime'da geçiş)
- **OS Katmanı:** Wine Translation Layer (prefix bazlı izolasyon)
- **Grafik:** MoltenVK & DXVK (DirectX → Vulkan → Metal) pipeline
- **Ses:** AVAudioSession düşük gecikme altyapısı
- **Girdi:** Sanal Gamepad + harici kol (MFi, PS5, Xbox) + relative mouse

### Xbox 360 (XeniOS) Emülasyon
- **CPU:** Xenon PowerPC → ARM64 JIT çevirisi
- **GPU:** Xenos ATI → Metal shader translation
- **Kernel:** Xbox 360 kernel syscall emülasyonu
- **Bellek:** 512MB birleşik bellek mimarisi (BE↔LE swap)
- **VFS:** STFS / GDFX Xbox disk format desteği
- **APU:** XMA/PCM ses çözümleme
- **HID:** Xbox 360 controller emülasyonu

### Platform Özellikleri
- **MetalFX:** Apple AI tabanlı upscaling (Temporal & Spatial)
- **JIT:** iOS W^X uyumlu MAP_JIT + dinamik JIT yönetimi
- **Bulut:** iCloud save senkronizasyonu
- **Shader Cache:** Shader ısıtma ile stutter önleme
- **Konsol Modu:** HDMI/AirPlay harici ekran desteği
- **Performans HUD:** FPS, JIT istatistikleri, önbellek sağlığı

---

## 🛠 Teknik Mimari

```
┌─────────────────────────────────────────────────┐
│              Swift / SwiftUI Frontend             │
│  LibraryView · SettingsDashboard · GameCardView   │
├─────────────────────────────────────────────────┤
│            Sources/CompatCore (Swift)             │
│  RuntimeHost · GameImportService · PrefixManager  │
├─────────────────────────────────────────────────┤
│            Sources/CompatUIKit (UIKit)            │
│  AppCoordinator · GameLibraryVC · LogVC           │
├─────────────────────────────────────────────────┤
│             RuntimeBridge.cpp (C++)               │
│      Box64/FEX ↔ Wine ↔ XeniOS Orchestration     │
├───────────────────┬─────────────────────────────┤
│  Box64 / FEX-Emu  │     Core/ (XeniOS C++)      │
│  libbox64.dylib   │  CPU · GPU · Memory · Kernel │
│  x86→ARM64 JIT    │  VFS · APU · HID             │
├───────────────────┴─────────────────────────────┤
│     29 Xenia Static Libraries (iOS ARM64)        │
│  xenia-base · xenia-cpu · xenia-gpu · xenia-    │
│  kernel · xenia-apu · xenia-vfs · ...            │
└─────────────────────────────────────────────────┘
```

---

## 📦 Derleme

### Gereksinimler
- macOS + Xcode (Swift derleyici)
- [Theos](https://theos.dev) build sistemi
- iOS SDK (arm64)

### Build Komutları
```bash
# IPA oluşturma
make package FINALPACKAGE=1 DEBUG=0 FOR_RELEASE=1 PACKAGE_FORMAT=ipa

# Geliştirme derlemesi
make package
```

### GitHub Actions
Otomatik build devre dışıdır. Manuel tetikleme:
1. [Actions](../../actions) sekmesine gidin
2. **Run workflow** butonuna tıklayın
3. Artifacts bölümünden `LocalCompat-IPA` dosyasını indirin

### Kurulum
- **SideStore**, **AltStore** veya **Sideloadly** ile cihazınıza yükleyin

---

## 📁 Proje Yapısı

```
projemm/
├── Core/                    # Xbox 360 (XeniOS) C++ emülasyon katmanı
│   ├── CPU/                 # Xenon PowerPC → ARM64 JIT
│   ├── GPU/                 # Xenos → Metal shader çevirisi
│   ├── Memory/              # 512MB birleşik bellek yönetimi
│   ├── Kernel/              # Xbox 360 kernel emülasyonu
│   ├── VFS/                 # STFS/GDFX dosya sistemi
│   ├── APU/                 # XMA/PCM ses sistemi
│   └── HID/                 # Controller emülasyonu
├── Sources/
│   ├── CompatCore/          # Çekirdek iş mantığı (Swift)
│   │   ├── Models/          # GameRecord, RuntimeConfiguration
│   │   └── Services/        # RuntimeHost, GameImportService
│   └── CompatUIKit/         # UIKit arayüz katmanı
├── Frameworks/              # libbox64.dylib
├── RuntimeBridge.cpp/.h     # Swift ↔ C++ köprüsü
├── *.swift                  # SwiftUI arayüz ve yönetici sınıfları
├── Makefile                 # Theos build sistemi
└── .github/workflows/       # CI/CD (manuel tetikleme)
```

---

## 📋 Dokümantasyon
- [`proje_ozeti.md`](proje_ozeti.md) — Detaylı geliştirme günlüğü
- [`hata_cozumleri.md`](hata_cozumleri.md) — Derleme hatası çözümleri
- [`detay.md`](detay.md) — Son build logları

---

## 📄 Lisans
Bu proje kişisel kullanım amaçlıdır.
