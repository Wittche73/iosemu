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
        // Create basic structure
        let dirs = [
            "\(masterPrefixPath)/drive_c/windows/system32",
            "\(masterPrefixPath)/drive_c/windows/syswow64",
            "\(masterPrefixPath)/drive_c/users/Public/Documents"
        ]
        
        for dir in dirs {
            try? fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
        
        // Robustly copy wine_payload from app bundle
        if let payloadURL = Bundle.main.url(forResource: "wine_payload", withExtension: nil) {
            copyDirectoryContents(from: payloadURL, to: URL(fileURLWithPath: masterPrefixPath))
            print("✅ WineDependencyManager: Master Prefix initialized with bundle payload.")
        }
        
        print("✅ WineDependencyManager: Master Prefix structure completed.")
    }
    
    private func copyDirectoryContents(from sourceURL: URL, to destURL: URL) {
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        guard let enumerator = fileManager.enumerator(at: sourceURL, includingPropertiesForKeys: nil, options: options) else { return }
        
        let sourcePath = sourceURL.path
        for case let fileURL as URL in enumerator {
            let fullPath = fileURL.path
            // Calculate relative path correctly
            var relativePath = fullPath.replacingOccurrences(of: sourcePath, with: "")
            if relativePath.hasPrefix("/") {
                relativePath.removeFirst()
            }
            
            if relativePath.isEmpty { continue }
            
            let targetURL = destURL.appendingPathComponent(relativePath)
            
            do {
                if fileURL.hasDirectoryPath {
                    try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
                } else {
                    // Create parent directory if it's a file but parent doesn't exist
                    let parentDir = targetURL.deletingLastPathComponent()
                    if !fileManager.fileExists(atPath: parentDir.path) {
                        try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
                    }
                    
                    if !fileManager.fileExists(atPath: targetURL.path) {
                        try fileManager.copyItem(at: fileURL, to: targetURL)
                    }
                }
            } catch {
                print("      ⚠️ Failed to copy \(relativePath): \(error)")
            }
        }
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
        let destSys32 = "\(prefixPath)/drive_c/windows/system32"
        
        print("   -> [DEPLOY] Temel kütüphaneler kontrol ediliyor: \(destSys32)")
        
        guard let payloadURL = Bundle.main.url(forResource: "wine_payload", withExtension: nil) else {
            print("      ❌ Hata: Uygulama paketinde wine_payload bulunamadı!")
            return
        }
        
        let sourceSys32 = payloadURL.appendingPathComponent("drive_c/windows/system32")
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: sourceSys32.path)
            for file in files {
                let src = sourceSys32.appendingPathComponent(file)
                let dst = URL(fileURLWithPath: "\(destSys32)/\(file)")
                
                if !fileManager.fileExists(atPath: dst.path) {
                    try fileManager.copyItem(at: src, to: dst)
                    print("      + \(file) -> Deployed")
                } else {
                    print("      . \(file) -> Already present")
                }
            }
        } catch {
            print("      ❌ Hata: DLL'ler kopyalanamadı - \(error)")
        }
    }
}
