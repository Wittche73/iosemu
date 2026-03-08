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
        print("[DEBUG] Setting up Master Prefix at: \(masterPrefixPath)")
        
        let currentPayloadVersion = "1.0.1" // Bu sürüm her güncellemede artırılmalıdır.
        let versionFilePath = "\(masterPrefixPath)/payload_version.txt"
        
        if fileManager.fileExists(atPath: versionFilePath) {
            if let existingVersion = try? String(contentsOfFile: versionFilePath, encoding: .utf8), 
               existingVersion == currentPayloadVersion {
                print("ℹ️ WineDependencyManager: Payload is already up to date (Version \(currentPayloadVersion)). Skipping sync.")
                return
            }
        }

        // Temel yapıyı oluştur
        let dirs = [
            "\(masterPrefixPath)/drive_c/windows/system32",
            "\(masterPrefixPath)/drive_c/windows/syswow64",
            "\(masterPrefixPath)/drive_c/users/Public/Documents"
        ]
        
        for dir in dirs {
            if !fileManager.fileExists(atPath: dir) {
                try? fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true)
            }
        }
        
        // Paketten wine_payload'ı kopyala
        syncPayload(to: masterPrefixPath)
        
        // Sürüm bilgisini kaydet
        try? currentPayloadVersion.write(toFile: versionFilePath, atomically: true, encoding: .utf8)
        
        print("✅ WineDependencyManager: Master Prefix structure completed and versioned.")
    }
    
    private func syncPayload(to targetPath: String) {
        let bundlePath = Bundle.main.bundlePath
        let payloadSourcePath = (bundlePath as NSString).appendingPathComponent("wine_payload")
        
        print("      [DEBUG] Payload Source: \(payloadSourcePath)")
        
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: payloadSourcePath, isDirectory: &isDir), isDir.boolValue else {
            print("      ❌ Hata: wine_payload bundle içinde bulunamadı!")
            return
        }
        
        recursiveSync(from: payloadSourcePath, to: targetPath)
    }
    
    private func recursiveSync(from source: String, to target: String) {
        let items = (try? fileManager.contentsOfDirectory(atPath: source)) ?? []
        
        for item in items {
            let srcPath = (source as NSString).appendingPathComponent(item)
            let dstPath = (target as NSString).appendingPathComponent(item)
            
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: srcPath, isDirectory: &isDir) {
                if isDir.boolValue {
                    if !fileManager.fileExists(atPath: dstPath) {
                        try? fileManager.createDirectory(atPath: dstPath, withIntermediateDirectories: true)
                    }
                    recursiveSync(from: srcPath, to: dstPath)
                } else {
                    // Akıllı Kontrol: Dosya boyutu veya tarihi değişmemişse atla
                    if fileManager.fileExists(atPath: dstPath) {
                        let srcAttr = try? fileManager.attributesOfItem(atPath: srcPath)
                        let dstAttr = try? fileManager.attributesOfItem(atPath: dstPath)
                        
                        if let srcSize = srcAttr?[.size] as? NSNumber,
                           let dstSize = dstAttr?[.size] as? NSNumber,
                           srcSize == dstSize {
                            // Boyut aynıysa atla (Hızlı kontrol)
                            return
                        }
                    }

                    do {
                        let isWine = item.lowercased() == "wine"
                        
                        var finalDstPath = dstPath
                        if isWine {
                            finalDstPath = (target as NSString).appendingPathComponent("wine.bin")
                        }
                        
                        if fileManager.fileExists(atPath: finalDstPath) {
                            try? fileManager.removeItem(atPath: finalDstPath)
                        }
                        try fileManager.copyItem(atPath: srcPath, toPath: finalDstPath)
                        // print("      * Updated: \(item)")
                    } catch {
                        print("      ❌ Failed to copy \(item): \(error)")
                    }
                }
            }
        }
    }
    
    /// Yeni bir oyun için master prefix'ten klonlama yapar
    func initializePrefix(for game: Game) {
        print("--- WineDependencyManager: Prefix Hazırlanıyor [\(game.name)] ---")
        
        if !fileManager.fileExists(atPath: game.prefixPath) {
            do {
                // APFS block cloning sayesinde bu işlem anlıktır (Zero-copy clone)
                try fileManager.copyItem(atPath: masterPrefixPath, toPath: game.prefixPath)
                print("   -> [CLONE SUCCESS] Master prefix copied to \(game.prefixPath)")
            } catch {
                print("   -> [CLONE ERROR] \(error)")
                try? fileManager.createDirectory(atPath: game.prefixPath, withIntermediateDirectories: true)
                syncPayload(to: game.prefixPath) // Klonlanamazsa manuel kopyala
            }
        } else {
            print("   -> [CLONE SKIP] Prefix already exists.")
        }
        
        // KRİTİK OPTİMİZASYON: initializePrefix artık her seferinde tam sync yapmaz.
        // Master prefix güncel olduğu sürece klon yeterlidir.
    }
}
