import Foundation

/// GPU ve Grafik çeviri (MoltenVK/DXVK) ayarlarını yöneten sınıf
class GraphicsManager {
    static let shared = GraphicsManager()
    
    private init() {}
    
    /// DXVK ve MoltenVK için gerekli çevre değişkenlerini hazırlar
    /// DXVK ve MoltenVK için gerekli çevre değişkenlerini hazırlar
    func prepareGraphicsEnvironment() -> [String: String] {
        var env: [String: String] = [:]
        
        // Gerçek Framework Yolları (IPA içindeki yerleşime göre)
        let frameworkBase = Bundle.main.bundlePath + "/Frameworks"
        
        // DXVK Ayarları
        env["DXVK_HUD"] = "compiler"
        env["MVK_CONFIG_LOG_LEVEL"] = "2" // Daha detaylı log
        env["VULKAN_SDK"] = frameworkBase + "/MoltenVK.framework"
        
        // Harici ekran bağlıysa çözünürlüğü artır
        if DisplayManager.shared.isExternalDisplayConnected() {
            print("   -> Harici Ekran Algılandı: 4K Ölçekleme Aktif")
            env["MVK_CONFIG_RES_SCALE"] = "2.0"
        }
        
        print("--- GraphicsManager: Gerçek GPU Katmanları (Framework Aware) Hazırlandı ---")
        return env
    }
    
    /// Grafik sistemini ilklendirir (C++ Bridge üzerinden)
    func initializeGraphics(for gameID: UUID) -> Bool {
        ShaderCacheManager.shared.warmUpCache(for: gameID)
        
        if init_graphics() {
            print("✅ GraphicsManager: MoltenVK/Vulkan katmanı başarıyla ilklendirildi.")
            return true
        } else {
            print("❌ GraphicsManager: Grafik ilklendirme hatası!")
            return false
        }
    }
}
