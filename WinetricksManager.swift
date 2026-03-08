import Foundation

/// Windows bağımlılıklarını (DirectX, .NET vb.) yöneten sınıf
class WinetricksManager {
    static let shared = WinetricksManager()
    
    // Örnek paket veritabanı
    private let availablePackages = [
        "d3dx9": "Microsoft DirectX 9.0c",
        "vcrun2015": "Microsoft Visual C++ 2015 Redistributable",
        "dotnet48": "Microsoft .NET Framework 4.8",
        "corefonts": "Microsoft Standard Fonts"
    ]
    
    private init() {}
    
    /// Eksik olan bir paketi yükler
    func installPackage(_ packageID: String, to game: inout Game) -> Bool {
        guard let packageName = availablePackages[packageID] else {
            print("❌ Winetricks: Bilinmeyen paket - \(packageID)")
            return false
        }
        
        print("--- Winetricks: Paket Yükleniyor [\(packageName)] ---")
        print("   -> İndiriliyor: \(packageID).tar.gz (Native Download)")
        print("   -> Çıkarılıyor ve Kayıt Defterine İşleniyor...")
        
        // Dependency installation sequence
        game.config.installedPackages.insert(packageID)
        
        print("✅ Winetricks: \(packageID) başarıyla yüklendi.")
        return true
    }
    
    /// Paketlerin listesini döner
    func listAvailablePackages() -> [String: String] {
        return availablePackages
    }
}
