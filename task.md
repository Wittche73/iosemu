📑 Project: LocalCompat (iOS GameHub-Style)
Technical Roadmap & Task List

1. Konteyner ve Prefix Mimarisi (Storage Layer)
- [x] Virtual Drive Mapping: Uygulama içinde C: ve D: mantığını iOS sandbox'ına tam entegre et. `[x]`
- [x] Container Isolation: Her oyunun kendi Registry, system.reg ve user.reg dosyalarına sahip olduğu izole klasör yapısını (RegistryManager/PrefixManager) tamamla. `[x]`
- [x] Portable Wine Payload: Wine binary'lerini Documents klasörüne "deploy" eden sistemi optimize et. `[x]`

2. Grafik ve Görüntü Sunumu (Display Layer)
- [x] X11/Wayland to Metal Bridge: Virtual Display Driver geliştir. `[x]`
- [x] MetalFX Integration: Apple'ın AI ölçekleme teknolojisini oyun çözünürlüğüne dinamik olarak bağla. `[x]`
- [x] DXVK / VKD3D Configuration: DirectX 11 ve 12 çağrılarını Vulkan (MoltenVK) üzerinden Metal'e çeviren config editörünü yap. `[x]`

3. Emülasyon Çekirdeği (Core Engine)
- [ ] Box64 DynaRec Optimization: iOS'un mprotect kısıtlamalarına uygun şekilde JIT sayfa yönetimini (RWX) geliştir.
- [ ] FEX-Emu Alternatifi: FEX-Emu çekirdeğini yedek motor olarak entegre et.
- [x] Wait/Sync Mechanism: Box64 ve Wine arasındaki senkronizasyonu sağlayan wineserver yönetimi. `[x]`

4. Girdi ve Kontrol Sistemleri (Input Layer)
- [x] Virtual Controller Overlay: Ekran üzerine özelleştirilebilir sanal gamepad ekle. `[x]`
- [x] Mouse/Keyboard Emulation: Relative Mouse Move moduna çeviren algoritmayı geliştir. `[x]`
- [x] MFi/GameController Support: PS5/Xbox kollarını Win32 XInput cihazı gibi tanıtacak köprüyü kur. `[x]`

5. Kullanıcı Deneyimi (Frontend Layer)
- [x] Game Discovery: .exe dosyalarını tarayıp kapak resimlerini çeken sistemi yaz. `[x]`
- [x] Per-Game Settings: JIT agresifliği, çözünürlük ve Wine versiyonu seçilebilen "Settings Dashboard"u oluştur. `[x]`
- [x] Performance HUD: Oyun sırasında FPS, CPU ve RAM kullanımını gösteren "Diagnostics" katmanını ekle. `[x]`

6. Gelişmiş Sistem Yönetimi (Advanced)
- [x] MemoryPressureManager: iOS hafıza uyarısı verdiğinde Wine heap'ini ve JIT cache'ini temizleyen mekanizma. `[x]`
- [x] Background Execution: ProcessAssertion ve ses oturumu hilelerini uygula. `[x]`
- [x] Winetricks Automation: Yaygın kütüphaneleri (d3dx9, vcrun) tek tıkla yükleyen sistem. (Fiziksel DLL transferi aktif) `[x]`

---
- [x] DXVK & MoltenVK Gerçek Framework Entegrasyonu `[x]`
- [x] İlk Gerçek x86 "Hello World" Binary Çalıştırılması `[x]`
- [x] Terminology Clear: Remove all "Simülatör" labels `[x]`
- [x] Functional Core: Real setenv/copy/monitoring logic `[x]`
