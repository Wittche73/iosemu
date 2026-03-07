import Foundation

/// Wine prefix'lerinin (C: sürücüsü, Registry vb.) fiziksel kurulumunu ve 
/// DLL bağımlılıklarının dağıtımını yöneten genişletilmiş sınıf.
class WineDependencyManager {
    static let shared = WineDependencyManager()
    
    private let fileManager = FileManager.default
    
    /// Ana şablon prefix dizini (Tüm oyunlar buradan kopyalanır)
    private let masterPrefixPath = "/home/f-rat/Documents/master_prefix"
    
    private init() {
        setupMasterPrefix()
    }
    
    /// İlk kurulumda temiz bir Wine dizin yapısı oluşturur
    private func setupMasterPrefix() {
        let dirs = [
            "\(masterPrefixPath)/drive_c/windows/system32",
            "\(masterPrefixPath)/drive_c/windows/syswow64",
            "\(masterPrefixPath)/drive_c/users/Public/Documents"
        ]
        
        for dir in dirs {
            try? fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
        print("✅ WineDependencyManager: Master Prefix iskeleti hazırlandı.")
    }
    
    /// Yeni bir oyun için master prefix'ten klonlama yapar
    func initializePrefix(for game: Game) {
        print("--- WineDependencyManager: Prefix Klonlanıyor [\(game.name)] ---")
        
        // Simüle: Master prefix klasörünü oyunun prefixPath'ine kopyala
        print("   -> [CLONE] \(masterPrefixPath) to \(game.prefixPath)")
        
        // Temel DLL'leri yerleştir
        deployCoreDLLs(to: game.prefixPath)
    }
    
    private func deployCoreDLLs(to prefixPath: String) {
        let system32 = "\(prefixPath)/drive_c/windows/system32"
        let coreDLLs = ["ntdll.dll", "kernel32.dll", "user32.dll", "gdi32.dll"]
        
        print("   -> [DEPLOY] Temel Windows kütüphaneleri yerleştiriliyor...")
        for dll in coreDLLs {
            print("      + \(dll) -> system32/")
        }
    }
}
