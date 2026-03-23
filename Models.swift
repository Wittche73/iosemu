import Foundation

/// Oyunun durumunu temsil eden enum
enum GameStatus: String, Codable {
    case idle
    case running
    case error
}

/// Oyunun platformunu temsil eden enum
enum Platform: String, Codable {
    case windows
    case xbox360
}

/// Performans profillerini temsil eden enum
enum PerformanceProfile: String, Codable {
    case powerSave
    case balanced
    case highPerformance
}

/// Prefix konfigürasyonunu temsil eden yapı
struct PrefixConfig: Codable {
    var windowsVersion: String = "win10"
    var dllOverrides: [String: String] = [:] // Örn: ["d3d11": "n,b"]
    var environmentVariables: [String: String] = [:]
    var performanceProfile: PerformanceProfile = .balanced
    var installedPackages: Set<String> = [] // Yüklenen Winetricks paketleri
}

/// Temel Oyun modeli
struct Game: Identifiable, Codable {
    let id: UUID
    var name: String
    var path: String
    var prefixPath: String
    var status: GameStatus
    var platform: Platform = .windows
    var lastLaunch: Date?
    var config: PrefixConfig = PrefixConfig()
}

/// Girdi profili (dokunmatik/gamepad)
struct LegacyInputProfile: Codable {
    let id: UUID
    var name: String
    var mapping: [String: String]
}

/// Log kaydı
struct GameLog: Identifiable, Codable {
    let id: UUID
    let gameID: UUID
    let message: String
    let timestamp: Date
}

/// CompatCore iskeleti
class CompatCore {
    private var games: [Game] = []
    
    func importGame(from path: String, suggestedName: String) -> Game {
        // Mükerrer kontrolü
        if let existing = games.first(where: { $0.path == path }) {
            return existing
        }

        let gameID = UUID()
        var prefixPath = ""
        do {
            prefixPath = try FilesystemManager.shared.createPrefix(for: gameID)
        } catch {
            print("Error creating prefix: \(error)")
        }
        
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        let detectedPlatform: Platform = (ext == "iso" || ext == "xex") ? .xbox360 : .windows
        
        let newGame = Game(id: gameID, name: suggestedName, path: path, prefixPath: prefixPath, status: .idle, platform: detectedPlatform)
        games.append(newGame)
        print("Imported game: \(suggestedName) [\(detectedPlatform.rawValue)] with prefix: \(prefixPath)")
        return newGame
    }

    /// Otomatik keşif başlatır ve yeni oyunları kütüphaneye ekler
    func discoverGames() -> [Game] {
        let urls = GameDiscoveryManager.shared.discoverExes()
        var newGames: [Game] = []
        
        for url in urls {
            let name = GameDiscoveryManager.shared.suggestName(for: url)
            let imported = importGame(from: url.path, suggestedName: name)
            newGames.append(imported)
        }
        
        return newGames
    }

    func fetchGames() -> [Game] {
        return games
    }
    
    func launchGame(id: UUID) {
        if let index = games.firstIndex(where: { $0.id == id }) {
            let game = games[index]
            
            if RuntimeLauncher.shared.launch(game: game) {
                games[index].status = .running
                games[index].lastLaunch = Date()
                print("🚀 Oyun başarıyla başlatıldı: \(game.name)")
            } else {
                games[index].status = .error
                print("❌ Oyun başlatılamadı: \(game.name)")
            }
        }
    }
    
    func fetchLogs(for gameID: UUID) -> [GameLog] {
        return [GameLog(id: UUID(), gameID: gameID, message: "Kernel initialized", timestamp: Date())]
    }
}
