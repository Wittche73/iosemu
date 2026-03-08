import Foundation

/// Cihaz kaynaklarını ve emülasyon agresifliğini yöneten sınıf
class PerformanceManager {
    static let shared = PerformanceManager()
    
    private init() {}
    
    /// Belirli bir profil için sistem ayarlarını uygular
    func applyProfile(_ profile: PerformanceProfile) {
        print("--- PerformanceManager: Profil Uygulanıyor [\(profile.rawValue)] ---")
        
        switch profile {
        case .powerSave:
            setenv("BOX64_DYNAREC_STRONGMEM", "1", 1)
            setenv("BOX64_DYNAREC_FASTROUND", "0", 1)
            setenv("BOX64_DYNAREC_FASTNAN", "0", 1)
            print("   -> Profile: Power Save (Safety Over Speed)")
        case .balanced:
            setenv("BOX64_DYNAREC_STRONGMEM", "0", 1)
            setenv("BOX64_DYNAREC_FASTROUND", "1", 1)
            print("   -> Profile: Balanced (Optimized)")
        case .highPerformance:
            setenv("BOX64_DYNAREC_STRONGMEM", "0", 1)
            setenv("BOX64_DYNAREC_FASTROUND", "1", 1)
            setenv("BOX64_DYNAREC_FASTNAN", "1", 1)
            setenv("BOX64_DYNAREC_X87_DOUBLE", "1", 1)
            print("   -> Profile: High Performance (Unleashed)")
        }
        
        print("✅ PerformanceManager: Ayarlar başarıyla güncellendi.")
    }
}
