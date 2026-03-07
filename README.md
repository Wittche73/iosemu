# LocalCompat

iOS cihazlarda x86/x64 tabanlı Windows oyunlarını yerel (native) olarak çalıştırmak için bir uyumluluk katmanı.

## 🚀 Özellikler
- **CPU Emülasyonu:** Box64 / FEX entegrasyonu.
- **Grafik:** MoltenVK & DXVK (DirectX -> Metal) desteği.
- **Performans:** Apple MetalFX Upscaling entegrasyonu.
- **Ses:** Düşük gecikmeli AVAudioSession altyapısı.
- **Girdi:** Sanal Gamepad ve harici kol (MFi, PS, Xbox) desteği.

## 🛠 Teknik Mimari
- **Frontend:** Swift / SwiftUI
- **Backend:** C++ / Wine / Box64 (iOS ARM64 için özel olarak çapraz derlenmiş `libbox64.dylib`)
- **Build System:** Theos & CMake

## 📦 Kurulum (IPA)
Bu repo üzerinde her commit sonrası otomatik olarak IPA dosyası derlenmektedir.
1. [Actions](../../actions) sekmesine gidin.
2. En son başarılı workflow çalışmasına tıklayın.
3. **Artifacts** bölümünden `LocalCompat-IPA` dosyasını indirin.
4. Sideloadly, AltStore veya SideStore ile cihazınıza yükleyin.

## 🛠 Geliştirme
Projeyi yerel ortamda derlemek için Theos gereklidir.
```bash
make package
```
