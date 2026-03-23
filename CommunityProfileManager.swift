import Foundation

/// Oyunlar için optimize edilmiş hazır ayar şablonlarını yöneten sınıf
class CommunityProfileManager {
    static let shared = CommunityProfileManager()
    
    /// Popüler oyunlar için hazır profil veritabanı (Verified Database)
    private let profiles: [String: [String: Any]] = [
        "Doom Eternal": [
            "windowsVersion": "win10",
            "dllOverrides": ["d3d11": "n,b", "dxgi": "n"],
            "performanceProfile": PerformanceProfile.highPerformance,
            "requiredPackages": ["d3dx11", "vcrun2017"]
        ],
        "Skyrim": [
            "windowsVersion": "win7",
            "dllOverrides": ["d3d9": "n,b"],
            "performanceProfile": PerformanceProfile.balanced,
            "requiredPackages": ["d3dx9", "xact"]
        ]
    ]
    
    private init() {}
    
    /// Belirli bir oyun ismine göre topluluk profilini döndürür
    func getProfile(for gameName: String) -> [String: Any]? {
        return profiles[gameName]
    }
    
    /// Bir oyuna topluluk profilini uygular
    func applyCommunityProfile(to game: inout Game) -> Bool {
        guard let profile = getProfile(for: game.name) else {
            print("ℹ️ CommunityProfile: \(game.name) için hazır profil bulunamadı.")
            return false
        }
        
        print("--- CommunityProfile: Ayarlar Uygulanıyor [\(game.name)] ---")
        
        if let winVer = profile["windowsVersion"] as? String {
            game.config.windowsVersion = winVer
        }
        
        if let overrides = profile["dllOverrides"] as? [String: String] {
            game.config.dllOverrides = overrides
        }
        
        if let perf = profile["performanceProfile"] as? PerformanceProfile {
            game.config.performanceProfile = perf
        }
        
        if let packages = profile["requiredPackages"] as? [String] {
            print("   -> Önerilen paketler: \(packages.joined(separator: ", "))")
            // Not: Paket yükleme işlemi kullanıcı onayına sunulmalı, burada sadece config'e not düşülebilir veya otomatik yüklenebilir.
        }
        
        print("✅ CommunityProfile: En iyi ayarlar başarıyla uygulandı.")
        return true
    }
}
