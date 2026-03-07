import Foundation

class FilesystemManager {
    static let shared = FilesystemManager()
    
    private init() {}
    
    /// Uygulamanın Documents dizinini döndürür (iOS Sandbox)
    var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Yeni bir Wine prefix (dizin yapısı) oluşturur
    func createPrefix(for gameID: UUID) throws -> String {
        let prefixURL = documentsDirectory.appendingPathComponent("prefixes/\(gameID.uuidString)")
        
        let subfolders = [
            "drive_c",
            "drive_c/windows",
            "drive_c/Program Files",
            "drive_c/users/current/Desktop",
            "drive_c/users/current/Documents"
        ]
        
        for folder in subfolders {
            let folderURL = prefixURL.appendingPathComponent(folder)
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        print("Created prefix structure at: \(prefixURL.path)")
        return prefixURL.path
    }
    
    /// Bir dosyayı prefix içindeki Program Files'a "yükler" (kopyalar)
    func deployGameFile(sourcePath: String, gameID: UUID) throws {
        let prefixURL = documentsDirectory.appendingPathComponent("prefixes/\(gameID.uuidString)/drive_c/Program Files")
        let fileName = (sourcePath as NSString).lastPathComponent
        let destinationURL = prefixURL.appendingPathComponent(fileName)
        
        // Simülasyon: Gerçek dosyayı kopyalamaya çalışalım (eğer varsa)
        // placeholder olduğu için şimdilik sadece print atıyoruz
        print("Deploying \(fileName) to \(destinationURL.path)")
    }
}
