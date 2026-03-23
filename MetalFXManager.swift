import Foundation

#if canImport(MetalFX)
import MetalFX
#endif

/// Apple's MetalFX (Upscaling) teknolojisini yöneten sınıf.
/// Düşük çözünürlüklü render'ları yapay zeka ile Retina/4K kalitesine yükseltir.
class MetalFXManager {
    static let shared = MetalFXManager()
    
    private init() {}
    
    enum UpscalingMode: Int {
        case off = 0
        case spatial = 1
        case temporal = 2
    }
    
    private var currentMode: UpscalingMode = .off
    
    /// MetalFX desteğini kontrol eder (A13 Bionic ve üzeri gerektirir)
    func isSupported() -> Bool {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return true
        }
        #endif
        return false
    }
    
    /// Belirli bir ölçekleme modunu aktif eder
    func enableUpscaling(_ mode: UpscalingMode) {
        self.currentMode = mode
        print("--- MetalFX: Ölçekleme Modu Değiştirildi [\(mode)] ---")
        
        // C++ Köprüsüne bildir
        enable_metalfx(Int32(mode.rawValue))
        
        #if os(iOS)
        switch mode {
        case .spatial:
            setenv("MVK_CONFIG_USE_METALFX", "1", 1)
            setenv("MVK_CONFIG_METALFX_TYPE", "spatial", 1)
        case .temporal:
            setenv("MVK_CONFIG_USE_METALFX", "1", 1)
            setenv("MVK_CONFIG_METALFX_TYPE", "temporal", 1)
        case .off:
            setenv("MVK_CONFIG_USE_METALFX", "0", 1)
        }
        #endif
        
        print("✅ MetalFX: Render pipeline yapılandırıldı.")
    }
}
