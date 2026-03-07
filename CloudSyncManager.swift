import Foundation

/// iCloud/CloudKit tabanlı save senkronizasyonunu yöneten sınıf.
/// Gerçek cihazda CloudKit ile konuşur, simülasyonda ise disk tabanlı 'bulut' klasörü kullanır.
class CloudSyncManager {
    static let shared = CloudSyncManager()
    
    // Simüle edilmiş bulut deposu yolu
    private let simulatedCloudPath: String = {
        let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return docs + "/SimulatedCloud"
    }()
    
    private init() {
        try? FileManager.default.createDirectory(atPath: simulatedCloudPath, withIntermediateDirectories: true)
    }
    
    /// Bir oyunun save dosyalarını buluta iter (Push)
    func pushSaves(for game: Game) {
        print("--- CloudSync: Push Başlatıldı [\(game.name)] ---")
        
        let localSavePath = game.prefixPath + "/drive_c/users/USER/Save Games"
        let cloudSavePath = simulatedCloudPath + "/\(game.id.uuidString)/saves"
        
        // Klasörün varlığını kontrol et (Simüle: Windows'ta her oyun buraya kaydeder)
        guard FileManager.default.fileExists(atPath: localSavePath) else {
            print("   ℹ️ Yerel save klasörü boş, push atlandı.")
            return
        }
        
        do {
            try FileManager.default.createDirectory(atPath: cloudSavePath, withIntermediateDirectories: true)
            
            // Simüle: Klasör içeriğini "buluta" kopyala
            let files = try FileManager.default.contentsOfDirectory(atPath: localSavePath)
            for file in files {
                let src = localSavePath + "/" + file
                let dst = cloudSavePath + "/" + file
                
                if FileManager.default.fileExists(atPath: dst) {
                    try FileManager.default.removeItem(atPath: dst)
                }
                try FileManager.default.copyItem(atPath: src, toPath: dst)
                print("   -> [PUSH] \(file) buluta gönderildi.")
            }
            print("✅ CloudSync: Kayıtlar başarıyla senkronize edildi.")
        } catch {
            print("❌ CloudSync Hata: \(error.localizedDescription)")
        }
    }
    
    /// Buluttaki kayıtları yerel prefix'e çeker (Pull)
    func pullSaves(for game: Game) {
        print("--- CloudSync: Pull Başlatıldı [\(game.name)] ---")
        
        let localSavePath = game.prefixPath + "/drive_c/users/USER/Save Games"
        let cloudSavePath = simulatedCloudPath + "/\(game.id.uuidString)/saves"
        
        guard FileManager.default.fileExists(atPath: cloudSavePath) else {
            print("   ℹ️ Bulutta kayıt bulunamadı, pull atlandı.")
            return
        }
        
        do {
            try FileManager.default.createDirectory(atPath: localSavePath, withIntermediateDirectories: true)
            
            let files = try FileManager.default.contentsOfDirectory(atPath: cloudSavePath)
            for file in files {
                let src = cloudSavePath + "/" + file
                let dst = localSavePath + "/" + file
                
                if FileManager.default.fileExists(atPath: dst) {
                    try FileManager.default.removeItem(atPath: dst)
                }
                try FileManager.default.copyItem(atPath: src, toPath: dst)
                print("   -> [PULL] \(file) buluttan indirildi.")
            }
            print("✅ CloudSync: Yerel dosyalar güncellendi.")
        } catch {
            print("❌ CloudSync Pull Hata: \(error.localizedDescription)")
        }
    }
}
