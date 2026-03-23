# LocalCompat Hata ve Çözüm Kayıtları

Bu dosya, geliştirme sürecinde karşılaşılan teknik engelleri ve bunların nasıl aşıldığını detaylandırmaktadır.

### 1. CI/CD ve Derleme Hataları
- **Hata:** `CompatCore` çakışmaları, `PrefixManager` isimlendirme karışıklıkları.
- **Çözüm:** Kod tabanındaki isimlendirme standartları güncellendi, eski iOS API'leri `UIWindowScene` uyumlu hale getirildi.
- **Hata:** C++ `-Werror` nedeniyle kullanılmayan değişken uyarısı (unused variable).
- **Çözüm:** Gerekli yerlere `(void)var` eklenerek veya değişken kaldırılarak derleme hatası giderildi.

### 2. IPA İmza ve SideStore Uyumluluğu
- **Hata:** SideStore'da imzalama sırasında `ldid.cpp(869)` hatasıyla çökme.
- **Çözüm:** Theos debug scriptlerinin Mach-O yapısını bozduğu anlaşıldı. Makefile'a `DEBUG=0` ve `FOR_RELEASE=1` eklenerek saf binary üretimi sağlandı.
- **Hata:** Kaynak kodların (.cpp, .swift) IPA içine dahil edilmesi.
- **Çözüm:** Makefile kaynak arama dizini (`wildcard`) düzeltilerek sadece gerekli binary ve resource'ların paketlenmesi sağlandı.

### 3. Kullanıcı Arayüzü (UI) Uyumlaştırması
- **Hata:** iPad/Pro Max cihazlarda Split-View modu nedeniyle UI bozulması.
- **Çözüm:** `.navigationViewStyle(.stack)` kullanılarak tam ekran deneyimi sabitlendi.
- **Hata:** Grid Layout'ta oyun kartlarının sola yapışması/kırpılması.
- **Çözüm:** `GameCardView` elemanlarına `maxWidth: .infinity` atanarak dengeli dağılım sağlandı.

### 4. Box64 iOS (Darwin/Mach-O) Derleme Hataları
- **Hata:** `isnanf` ve `isinff` makrolarının eksikliği.
- **Çözüm:** Apple SDK uyumlu `isnan` ve `isinf` fonksiyonlarına köprü kuruldu.
- **Hata:** `_pthread_cleanup_push` linker hatası.
- **Çözüm:** Apple libc'deki farklı yapı nedeniyle bu bloklar `__APPLE__` makrolarıyla sarılıp devredışı bırakıldı.
- **Hata:** Linux'a özgü `__libc_memalign` çağrısı.
- **Çözüm:** `posix_memalign` tabanlı `apple_memalign` sarmalayıcısı yazıldı.
- **Hata:** Linker'ın iOS platform sürümünü ve mimarisini tanımaması.
- **Çözüm:** `-Wl,-platform_version,ios` ve `-arch arm64` bayrakları CMake'e eklendi.

### 5. Sembol Görünürlüğü ve Entry Point
- **Hata:** `libbox64.dylib` içinde `main` sembolünün bulunamaması.
- **Çözüm:** Fonksiyon `box64_main` olarak adlandırıldı ve `__attribute__((visibility("default")))` ile ihraç edildi.
- **Hata:** Apple linker'ının sembol başına `_` eklemesi.
- **Çözüm:** `RuntimeBridge.cpp` içerisine fallback olarak `_box64_main` arama desteği eklendi.

### 6. iOS Sandbox ve Çevre Değişkenleri
- **Hata:** `environ` değişkenine erişim hatası (Sandbox kısıtlaması).
- **Çözüm:** `_NSGetEnviron()` fonksiyonu kullanılarak çevre değişkenlerine erişim sağlandı.
- **Hata:** Box64'ün `/home` gibi yasaklı dizinlere yazmaya çalışması.
- **Çözüm:** `HOME` ve `WINEPREFIX` değişkenleri oyunun prefix klasörüne yönlendirilerek Sandbox ihlalleri engellendi.

### 8. Erken Başlangıç Takılması (Early Hang)
- **Hata:** `b64_main` çağrıldıktan hemen sonra motorun log üretmeden %99 CPU ile takılması.
- **Çözüm:** 
    1. `shm_open` Takılması: Box64'ün varsayılan config dosyasını açarken kullandığı `shm_open` fonksiyonu iOS'ta takılabiliyor. `BOX64_NOENVFILES=1` ile bu süreç devre dışı bırakıldı.
    2. `init_auxval` Bellek Hatası: Box64, kütüphane olarak çağrıldığında ortam değişkenlerinin (envp) arkasında `auxval` vektörü olduğunu varsayıyor. Bu durum iOS'ta rastgele bellek okunmasına ve sonsuz döngüye yol açabildiği için `b64_main`'e özel, temiz ve çift NULL sonlandırmalı bir env dizisi geçildi.
    3. Donanım Taraması: `BOX64_SYSINFO_CACHED` ile `/proc` ve `/sys` taramaları tamamen baypas edildi.

### 9. Swift ve SDK Uyumluluk Sorunları
- **Hata:** `DynamicJITManager` derlenirken `HOST_CPU_LOAD_INFO_COUNT` makrosunun bulunamaması.
- **Çözüm:** Bu değer (4) Swift katmanında manuel sabit (constant) olarak tanımlanarak SDK kısıtlaması aşıldı.
- **Hata:** Makefile içinde yeni eklenen Swift dosyalarının (`RegistryManager`, `MemoryPressureManager`) derlenmemesi.
- **Çözüm:** Makefile revize edilerek tüm kaynak dosyalar `LocalCompat_FILES` listesine eklendi.

### 10. Gelişmiş Çalışma Zamanı (Runtime) İyileştirmeleri
- **Hata:** Audio Session Code -50 (ParamErr) hatası.
- **Çözüm:** `.gameChat` modu yerine daha kararlı olan `.playback` ve `.default` kombinasyonuna geçildi.
- **Hata:** Yeni oluşturulan prefixlerde `system.reg` bulunamadığı için Registry ayarlarının atlanması.
- **Çözüm:** `RegistryManager` geliştirilerek dosya yoksa otomatik olarak temiz bir Wine Registry başlığıyla ilklendirme yapması sağlandı.

### 11. CI/CD Stabilizasyon ve Derleme Hataları (Final)
- **Hata:** `InputManager` içinde `gamepad.leftTrigger.isPressed > 0.5` karşılaştırma hatası (Bool vs Double).
- **Çözüm:** `isPressed` (Bool) yerine `value` (Float) kullanılarak mantıksal karşılaştırma düzeltildi.
- **Hata:** `RuntimeLauncher` derlenirken `PerformanceManager` içinde `applyProfile` metodunun bulunamaması.
- **Çözüm:** `PerformanceManager` sınıfına eksik olan `applyProfile` metodu ve profil bazlı çevre değişkeni atamaları eklendi.
- **Hata:** `onChange` metodunun iOS 17'de "deprecated" uyarısı vermesi.
- **Çözüm:** Modern Swift closure sözdizimine geçilerek uyarılar giderildi.

### 12. Linker Hataları ve Eksik Semboller (Final)
- **Hata:** `_enable_metalfx` sembolünün bulunamaması (Undefined symbol).
- **Çözüm:** `RuntimeBridge.h` içinde tanımlı olan ancak `RuntimeBridge.cpp` içinde unutulan `enable_metalfx` fonksiyonu implemente edildi.
- **Hata:** `CoreAudioTypes` framework uyarısı.
- **Çözüm:** Bu bir "auto-link" uyarısıdır; ancak sembol hatası giderilince Linking aşaması başarıyla tamamlanabilir.
- **Hata:** `PerformanceManager` içinde süslü parantez (`}`) eksikliği ve `applyProfile` metodunun yanlış hizada olması.
- **Çözüm:** `setJITLevel` fonksiyonu kapatıldı ve `applyProfile` sınıf seviyesine taşındı.
- **Hata:** `PerformanceProfile` enum uyuşmazlığı (`.powerSaving` vs `.powerSave`).
- **Çözüm:** Kod tabanı `Models.swift` ile uyumlu hale getirildi.
### 13. iOS JIT (W^X) ve Bellek İzin Hataları
- **Hata:** JIT kod üretimi sırasında `mprotect` çağrılarının iOS üzerinde başarısız olması veya `EXC_BAD_ACCESS` çökmesi.
- **Çözüm:** 
    1. Bellek eşlemede `MAP_JIT` bayrağı zorunlu kılındı.
    2. Apple'a özgü `pthread_jit_write_protect_np` API'si kullanılarak kod yazılmadan hemen önce koruma kaldırıldı (`DISABLE`), işlem bitince geri açıldı (`ENABLE`).
    3. `dynarec_native.c` içindeki ana derleme döngüsü (FillBlock64) bu koruma mekanizmasıyla sarmalandı.

### 14. Dinamik Motor Yükleme (Symbol Table) Hataları
- **Hata:** C++ bridge üzerinden FEX ve Box64 arasında geçiş yaparken dylib sembollerinin çakışması veya bulunamaması.
- **Çözüm:** `dlopen` ve `dlsym` mantığı generic hale getirildi. Her iki motorun `main` entry pointleri için fallback mekanizması kuruldu ve `current_engine` değişkeni üzerinden izolasyon sağlandı.
91: 
92: ### 15. Yerel Derleme (Local Build) ve Araç Takımı Hataları
93: - **Hata:** `bash: .../bin/clang: Böyle bir dosya ya da dizin yok` (Theos'un linux-iphone araç takımı eksikliği).
94: - **Çözüm:** Sistemdeki `clang`, `ldid` ve `strip` araçları `$THEOS/toolchain/linux/iphone/bin/` dizinine sembolik bağlar ile bağlanarak derleme yolu tamir edildi.
95: - **Hata:** `swift-build: error while loading shared libraries: libxml2.so.2` (Swift bağımlılık hatası).
96: - **Çözüm:** Ubuntu üzerinde `libxml2-dev` ve `libxml2-utils` paketleri kuruldu; `LD_LIBRARY_PATH` değişkenine kütüphane yolu (`/usr/lib/x86_64-linux-gnu/`) eklenerek Swift araç setinin çalışması sağlandı.
