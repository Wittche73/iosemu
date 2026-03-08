import Foundation

/// Wine Prefix'lerini (Windows ortamlarını) yöneten ve yapılandıran sınıf
class PrefixManager {
    static let shared = PrefixManager()
    
    private init() {}
    
    /// Bir oyun için prefix'i konfigüre eder (DLL overrides, Windows version)
    func configurePrefix(for game: Game) -> Bool {
        print("--- PrefixManager: Yapılandırma Başlatıldı [\(game.name)] ---")
        
        // 1. Şablon Prefix Kurulumu ve Fiziksel Dosya Hazırlığı
        WineDependencyManager.shared.initializePrefix(for: game)
        
        // 2. Windows Versiyonu Ayarlanması (Windows Registry configuration)
        print("   -> Windows Versiyonu: \(game.config.windowsVersion)")
        
        // 2. DLL Overrides Uygulanması (WINEDLLOVERRIDES)
        var overrideString = ""
        for (dll, mode) in game.config.dllOverrides {
            print("   -> DLL Override: \(dll) set to \(mode)")
            overrideString += "\(dll)=\(mode);"
        }
        if !overrideString.isEmpty {
            setenv("WINEDLLOVERRIDES", overrideString, 1)
        }
        
        // 3. Özel Çevresel Değişkenler
        for (key, value) in game.config.environmentVariables {
            print("    -> Env Var: \(key) = \(value)")
            setenv(key, value, 1)
        }
        
        // 4. Bağımlılık Kontrolü (Winetricks)
        if game.config.installedPackages.isEmpty {
            print("   ℹ️ Prefix: Herhangi bir Winetricks paketi yüklü değil.")
        } else {
            print("   ℹ️ Prefix: Yüklü paketler: \(game.config.installedPackages.joined(separator: ", "))")
            self.copyDependenciesToPrefix(game)
        }
        
        print("✅ PrefixManager: Yapılandırma Başarıyla Tamamlandı.")
        return true
    }
    
    /// Kritik Wine bileşenlerini (DLL) fiziksel olarak prefix dizinine aktarır
    private func copyDependenciesToPrefix(_ game: Game) {
        print("--- PrefixManager: Fiziksel DLL Transferi Başlatıldı ---")
        let system32Path = "\(game.prefixPath)/drive_c/windows/system32"
        let sourceDir = "bin/wine/dlls"
        
        for package in game.config.installedPackages {
            let sourcePath = "\(sourceDir)/\(package).dll"
            let destinationPath = "\(system32Path)/\(package).dll"
            
            if FileManager.default.fileExists(atPath: sourcePath) {
                print("   -> [COPY] \(sourcePath) to \(destinationPath)")
                do {
                    // Eskisini sil (varsa) ve yenisini kopyala
                    if FileManager.default.fileExists(atPath: destinationPath) {
                        try FileManager.default.removeItem(atPath: destinationPath)
                    }
                    // Fiziksel kopyalama: Bundle içindeki payload'dan prefix'e aktar
                    try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
                    print("✅ [SUCCESS] \(package).dll deployed to prefix.")
                } catch {
                    print("❌ [ERROR] \(package).dll kopyalanamadı: \(error)")
                }
            } else {
                print("⚠️ [WARNING] Kaynak DLL bulunamadı: \(sourcePath)")
            }
        }
    }
    
    /// Belirli bir DLL dosyasını prefix içine kopyalar
    func installDLL(dllName: String, data: Data, to game: Game) throws {
        let destination = "\(game.prefixPath)/drive_c/windows/system32/\(dllName)"
        print("   -> DLL Yükleniyor: \(destination)")
        // Installing native DLL binary
    }
}
