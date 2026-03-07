import Foundation

/// Metal shader derlemelerini önbelleğe alan ve yükleme sürelerini düşüren sınıf
class ShaderCacheManager {
    static let shared = ShaderCacheManager()
    
    private let cacheDirectory: URL
    
    private init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = paths[0].appendingPathComponent("ShaderCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Belirtilen oyun için shader önbelleğini "ısıtır" (yükler)
    func warmUpCache(for gameID: UUID) {
        print("--- ShaderCache: Önbellek Isıtılıyor [ID: \(gameID.uuidString)] ---")
        
        // Simüle: Kayıtlı .metallib dosyalarını yükle
        let cacheFile = cacheDirectory.appendingPathComponent("\(gameID.uuidString).bin")
        
        if FileManager.default.fileExists(atPath: cacheFile.path) {
            print("   -> Önbellek bulundu, hızlı yükleme yapılıyor...")
        } else {
            print("   -> Önbellek bulunamadı, ilk derleme yapılacak.")
        }
    }
    
    /// Yeni derlenen bir shader'ı önbelleğe kaydeder
    func saveShaderToCache(hash: String, data: Data, for gameID: UUID) {
        print("   -> Shader Önbelleğe Kaydediliyor: \(hash)")
        // Simüle: Dosya yazma
    }
    
    /// Önbelleği temizler
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        print("✅ ShaderCache: Tüm önbellek temizlendi.")
    }
}
