import Foundation

/// Sandbox içindeki .exe dosyalarını otomatik olarak tarayan ve keşfeden sınıf
class GameDiscoveryManager {
    static let shared = GameDiscoveryManager()
    
    private init() {}
    
    /// Documents/Games klasörünü tarar ve yeni oyunları bulur
    func discoverExes() -> [URL] {
        let documentsURL = FilesystemManager.shared.documentsDirectory
        let gamesURL = documentsURL.appendingPathComponent("Games")
        
        // Klasör yoksa oluştur (Boş kütüphane durumu için)
        if !FileManager.default.fileExists(atPath: gamesURL.path) {
            try? FileManager.default.createDirectory(at: gamesURL, withIntermediateDirectories: true, attributes: nil)
            return []
        }
        
        var discoveredExes: [URL] = []
        let enumerator = FileManager.default.enumerator(at: gamesURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) { (url, error) -> Bool in
            print("Error enumerating \(url): \(error)")
            return true
        }
        
        while let fileURL = enumerator?.nextObject() as? URL {
            // Sadece desteklenen sistem uzantılarını al
            let ext = fileURL.pathExtension.lowercased()
            if ext == "exe" || ext == "iso" || ext == "xex" {
                let path = fileURL.path
                if !path.contains("/prefixes/") && !path.contains("/windows/") {
                    discoveredExes.append(fileURL)
                }
            }
        }
        
        return discoveredExes
    }
    
    /// EXE dosyasından isim tahmini yapar (Örn: "DoomEternal.exe" -> "Doom Eternal")
    func suggestName(for url: URL) -> String {
        let baseName = url.deletingPathExtension().lastPathComponent
        // CamelCase ayırma ve alt çizgileri boşlukla değiştirme
        let spaced = baseName.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        return spaced.capitalized
    }
}
