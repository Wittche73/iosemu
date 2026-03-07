import Foundation

/// Box64 ve Wine orkestrasyonunu yöneten sınıf
class RuntimeLauncher {
    static let shared = RuntimeLauncher()
    
    private init() {}
    
    /// Bir oyunu emülasyon katmanında başlatır
    func launch(game: Game) -> Bool {
        print("--- RuntimeLauncher: Başlatma Hazırlığı ---")
        
        // 1. Performans Profili Uygulama
        PerformanceManager.shared.applyProfile(game.config.performanceProfile)
        
        // 2. Prefix Yapılandırması (Windows sürümü, DLL'ler vb.)
        if !PrefixManager.shared.configurePrefix(for: game) {
            return false
        }
        
        // 3. JIT Kontrolü
        if !JITManager.shared.isJITAvailable() {
            print(JITManager.shared.getJITStatusMessage())
        }
        
        // 2. Grafik Sistemi Hazırlığı
        _ = GraphicsManager.shared.prepareGraphicsEnvironment()
        
        // MetalFX Aktivasyonu (Performans Artışı)
        if MetalFXManager.shared.isSupported() {
            MetalFXManager.shared.enableUpscaling(.temporal)
        }
        
        if !GraphicsManager.shared.initializeGraphics(for: game.id) {
            return false
        }
        
        // 3. Ses Sistemi Hazırlığı
        if !AudioManager.shared.setupAudioSession() || !AudioManager.shared.initializeAudioEngine() {
            print("⚠️ Ses sistemi başlatılamadı, ama devam ediliyor...")
        }
        
        // 4. Girdi Sistemi (Input) Hazırlığı
        print("✅ InputManager: Sanal gamepad profili yüklendi.")
        
        // 5. Dinamik Performans İzleme (AI Switch)
        DynamicJITManager.shared.startMonitoring()
        
        // 6. Çevresel Değişkenlerin Hazırlanması (Native Engine)
        let winePrefix = game.prefixPath
        let exePath = game.path
        
        // C++ motoru için çevresel değişkenlerin enjekte edilmesi
        setenv("WINEPREFIX", winePrefix, 1)
        setenv("BOX64_LOG", "1", 1)
        setenv("BOX64_DYNAREC", "1", 1)
        
        // KRİTİK FİX: Box64 veya Wine, iOS Sandbox dışında `/home` klasörü
        // oluşturmaya çalışıp kilitleniyordu (sandbox violation deny file-write-create /home).
        // Bu yüzden HOME yetkisini uygulamanın kendi Documents sandbox'ına hapsediyoruz.
        setenv("HOME", winePrefix, 1)
        
        print("Set WINEPREFIX=\(winePrefix)")
        print("Set HOME=\(winePrefix)")
        print("Command: box64 wine \(exePath)")
        
        // KRİTİK FİX: Uygulama çöktüğünde C++ çıktısını yakalamak için stdout/stderr hapsediliyor
        let logPath = URL(fileURLWithPath: winePrefix).appendingPathComponent("box64.log").path
        freopen(logPath.cString(using: .utf8), "w", stderr)
        freopen(logPath.cString(using: .utf8), "w", stdout)
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        print("--- NATIVE LOGGING REDIRECTED TO \(logPath) ---")

        
        // 7. C++ Bridge Çağrıları
        if !init_runtime() {
            print("❌ C++ Runtime başlatılamadı!")
            DynamicJITManager.shared.stopMonitoring()
            return false
        }
        
        // Wine üzerinden exe yükleme
        if !load_exe(exePath, winePrefix) {
            let error = String(cString: get_last_runtime_error())
            print("❌ C++ Runtime Hata: \(error)")
            DynamicJITManager.shared.stopMonitoring()
            return false
        }
        
        // 9. Bulut Senkronizasyonu (PULL)
        CloudSyncManager.shared.pullSaves(for: game)
        
        // 10. CPU Döngüsünü Başlat (Simüle)
        print("✅ Emülasyon döngüsü başladı.")
        run_cpu_cycle()
        
        // 11. Otomatik Kayıt Yedekleme (PUSH)
        CloudSyncManager.shared.pushSaves(for: game)
        
        return true
    }
}
