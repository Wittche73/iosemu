import Foundation

/// Cihaz kaynaklarını ve emülasyon agresifliğini yöneten sınıf
class PerformanceManager {
    static let shared = PerformanceManager()
    
    private init() {}
    
    /// JIT Agresifliğini seviye bazlı ayarlar (0: Safe, 1: Fast, 2: Aggressive)
    func setJITLevel(_ level: Int) {
        print("--- PerformanceManager: JIT Seviyesi Ayarlanıyor [\(level)] ---")
        
        switch level {
        case 0: // Safe
            setenv("BOX64_DYNAREC_SAFEFLAGS", "1", 1)
            setenv("BOX64_DYNAREC_FASTROUND", "0", 1)
        case 1: // Fast (Default)
            setenv("BOX64_DYNAREC_SAFEFLAGS", "0", 1)
            setenv("BOX64_DYNAREC_FASTROUND", "1", 1)
        case 2: // Aggressive
            setenv("BOX64_DYNAREC_SAFEFLAGS", "0", 1)
            setenv("BOX64_DYNAREC_FASTROUND", "1", 1)
            setenv("BOX64_DYNAREC_BIGBLOCK", "2", 1)
        default:
            break
        }
    
    /// Belirtilen performans profilini sisteme uygular
    func applyProfile(_ profile: PerformanceProfile) {
        print("--- PerformanceManager: Uygulanan Profil -> \(profile) ---")
        
        switch profile {
        case .powerSaving:
            setJITLevel(0)
            setenv("BOX64_DYNAREC_WAIT", "1", 1)
        case .balanced:
            setJITLevel(1)
            setenv("BOX64_DYNAREC_WAIT", "0", 1)
        case .highPerformance:
            setJITLevel(2)
            setenv("BOX64_DYNAREC_WAIT", "0", 1)
            setenv("BOX64_DYNAREC_STRONGMEM", "1", 1)
        }
    }
}
