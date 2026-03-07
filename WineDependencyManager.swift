import Foundation

/// Wine prefix'lerinin (C: sürücüsü, Registry vb.) fiziksel kurulumunu ve 
/// DLL bağımlılıklarının dağıtımını yöneten genişletilmiş sınıf.
class WineDependencyManager {
    static let shared = WineDependencyManager()
    
    private let fileManager = FileManager.default
    
    /// Ana şablon prefix dizini (Tüm oyunlar buradan kopyalanır)
    private lazy var masterPrefixPath: String = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("master_prefix").path
    }()
    
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
        
        // Copy wine payload from app bundle if it exists
        if let payloadURL = Bundle.main.url(forResource: "wine_payload", withExtension: nil) {
            let winDir = "\(masterPrefixPath)/drive_c/windows"
            
            // For system32 specifically
            let sourceSys32 = payloadURL.appendingPathComponent("drive_c/windows/system32")
            let destSys32 = URL(fileURLWithPath: "\(winDir)/system32")
            
            if fileManager.fileExists(atPath: sourceSys32.path) {
                do {
                    let files = try fileManager.contentsOfDirectory(atPath: sourceSys32.path)
                    for file in files {
                        let src = sourceSys32.appendingPathComponent(file)
                        let dst = destSys32.appendingPathComponent(file)
                        if !fileManager.fileExists(atPath: dst.path) {
                            try fileManager.copyItem(at: src, to: dst)
                        }
                    }
                    print("✅ WineDependencyManager: Core payload copied to Master Prefix.")
                } catch {
                    print("❌ WineDependencyManager: Failed to copy payload - \(error)")
                }
            }
        }
        
        print("✅ WineDependencyManager: Master Prefix iskeleti hazırlandı.")
    }
    
    /// Yeni bir oyun için master prefix'ten klonlama yapar
    func initializePrefix(for game: Game) {
        print("--- WineDependencyManager: Prefix Klonlanıyor [\(game.name)] ---")
        
        let destURL = URL(fileURLWithPath: game.prefixPath)
        let sourceURL = URL(fileURLWithPath: masterPrefixPath)
        
        do {
            if !fileManager.fileExists(atPath: destURL.path) {
                try fileManager.copyItem(at: sourceURL, to: destURL)
                print("   -> [CLONE SUCCESS] \(masterPrefixPath) to \(game.prefixPath)")
            } else {
                print("   -> [CLONE SKIP] Prefix already exists for \(game.name)")
            }
        } catch {
            print("   -> [CLONE ERROR] Failed to clone prefix: \(error)")
        }
        
        // Temel DLL'leri yerleştir
        deployCoreDLLs(to: game.prefixPath)
    }
    
    private func deployCoreDLLs(to prefixPath: String) {
        let system32 = "\(prefixPath)/drive_c/windows/system32"
        let coreDLLs = ["ntdll.dll", "kernel32.dll", "user32.dll", "gdi32.dll"]
        
        print("   -> [DEPLOY] Temel Windows kütüphaneleri yerleştiriliyor/kontrol ediliyor: \(system32)")
        for dll in coreDLLs {
            if fileManager.fileExists(atPath: "\(system32)/\(dll)") {
                print("      + \(dll) -> Present")
            } else {
                print("      - \(dll) -> Missing!")
            }
        }
    }
}
