# LocalCompat Roadmap & Tasks

## 1. Kısa Vade (İlk 1 Ay) - Temel Altyapı
- [x] Swift Domain Modelleri ve Test Ortamı `[x]`
- [x] Filesystem Bridge: iOS Sandbox içinde Wine/Windows dizin yapısı `[x]`
- [x] JIT Bridge: Debugging modunda JIT kontrolü `[x]`
- [x] RuntimeBridge (C++): Box64/FEX iskelet entegrasyonu `[x]`
- [x] Minimal "Hello World" .exe çalıştırılması `[x]`

## 2. Orta Vade (1-2 Ay) - Grafik ve Girdi
- [x] MoltenVK/DXVK Entegrasyonu (DirectX -> Metal) `[x]`
- [x] Ses Motoru (OpenAL/SDL_Audio) `[x]`
- [x] Virtual Gamepad (Dokunmatik Kontroller) `[x]`
- [x] MFi (Gamepad) desteği `[x]`

## 3. Uzun Vade (3 Ay+) - UI ve Optimizasyon
- [x] Gelişmiş Oyun Kütüphanesi ve Kapak Resmi Yönetimi `[x]`
- [x] Prefix Yönetimi (Oyun başına izole Wine ayarları) `[x]`
- [x] Harici Ekran Desteği (HDMI / AirPlay) `[x]`
- [x] Shader Cache (Takılmaları Önleme Sistemi) `[x]`
- [x] Topluluk Profilleri ve Tek Tık Kurulum `[x]`
- [x] Dinamik JIT Switch (AI Destekli Performans) `[x]`
- [x] MetalFX Upscaling Entegrasyonu `[x]`
- [x] App Store Hazırlığı (Premium Iconlar & Splash) `[x]`
- [x] Bulut Senkronizasyonu (Save & Profil) ` [x]`

## 4. Gerçek Motor Entegrasyonu (Real Engine Implementation)
- [x] Ubuntu üzerinde iOS Derleme Ortamı (Theos & SDK) Hazırlığı `[x]`
- [x] Box64 (x86-on-ARM) Cross-Compilation ve Statik Bağlama `[x]`
- [x] Wine Bileşenlerinin (DLLs) Fiziksel Sandbox Transferi `[x]`
- [x] DXVK & MoltenVK Gerçek Framework Entegrasyonu `[x]`
- [x] İlk Gerçek x86 "Hello World" Binary Çalıştırılması `[x]`
- [x] App Store Hazırlığı (Premium Iconlar & Splash) `[x]`
- [x] Bulut Senkronizasyonu (Save & Profil) ` [x]`
