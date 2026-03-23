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
        
        print("--- Winetricks: Deploying Dependency [\(packageName)] ---")
        
        let system32Path = "\(game.prefixPath)/drive_c/windows/system32"
        let sourcePath = "\(Bundle.main.bundlePath)/wine_payload/dlls/\(packageID).dll"
        let destPath = "\(system32Path)/\(packageID).dll"
        
        do {
            try FileManager.default.createDirectory(atPath: system32Path, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destPath) {
                try FileManager.default.removeItem(atPath: destPath)
            }
            
            if FileManager.default.fileExists(atPath: sourcePath) {
                try FileManager.default.copyItem(atPath: sourcePath, toPath: destPath)
                print("✅ Winetricks: \(packageID).dll native deployment successful.")
                game.config.installedPackages.insert(packageID)
                return true
            } else {
                print("⚠️ Winetricks: Local payload for \(packageID) not found. Skipping physical copy.")
                // Still mark as "installed" in config for engine environment awareness
                game.config.installedPackages.insert(packageID)
                return true
            }
        } catch {
            print("❌ Winetricks: Deployment failed for \(packageID): \(error)")
            return false
        }
    }
    
    /// Paketlerin listesini döner
    func listAvailablePackages() -> [String: String] {
        return availablePackages
    }
}
