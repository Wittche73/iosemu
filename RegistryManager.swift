import Foundation

/// Wine'ın Registry dosyalarını (.reg) programatik olarak manipüle eden sınıf
class RegistryManager {
    static let shared = RegistryManager()
    
    private init() {}
    
    /// Belirli bir prefix içindeki system.reg dosyasında anahtar günceller
    func setRegistryValue(prefixPath: String, hive: String, key: String, value: String) {
        let regFilePath = "\(prefixPath)/\(hive).reg"
        let fileURL = URL(fileURLWithPath: regFilePath)
        
        print("--- RegistryManager: Updating \(hive).reg [Key: \(key)] ---")
        
        do {
            guard FileManager.default.fileExists(atPath: regFilePath) else {
                print("⚠️ Registry: File not found at \(regFilePath). Skipping.")
                return
            }
            
            var content = try String(contentsOf: fileURL, encoding: .utf8)
            
            // Basit bir regex ile anahtarı bulup değiştirme (veya ekleme)
            // Not: Gerçek bir Wine .reg dosyası karmaşıktır, bu temel bir implementasyondur.
            if content.contains(key) {
                // Mevcut değeri güncelle
                let lines = content.components(separatedBy: .newlines)
                var newLines = [String]()
                for line in lines {
                    if line.contains("\"\(key)\"=") {
                        newLines.append("\"\(key)\"=\"\(value)\"")
                    } else {
                        newLines.append(line)
                    }
                }
                content = newLines.joined(separator: "\n")
            } else {
                // Anahtar yoksa en sona ekle (Blok yapısı gözetilerek iyileştirilebilir)
                content += "\n\"\(key)\"=\"\(value)\"\n"
            }
            
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Registry: Key \(key) set to \(value) successfully.")
            
        } catch {
            print("❌ Registry: Failed to update registry: \(error)")
        }
    }
    
    /// Windows versiyonunu Registry üzerinden ayarlar
    func setWindowsVersion(prefixPath: String, version: String) {
        // HKLM\Software\Microsoft\Windows NT\CurrentVersion
        setRegistryValue(prefixPath: prefixPath, hive: "system", key: "CurrentVersion", value: version == "win10" ? "10.0" : "6.1")
    }
}
