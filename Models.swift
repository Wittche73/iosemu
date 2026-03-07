import Foundation

/// Oyunun durumunu temsil eden enum
enum GameStatus: String, Codable {
    case idle
    case running
    case error
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
        let gameID = UUID()
        var prefixPath = ""
        do {
            prefixPath = try FilesystemManager.shared.createPrefix(for: gameID)
        } catch {
            print("Error creating prefix: \(error)")
        }
        
        let newGame = Game(id: gameID, name: suggestedName, path: path, prefixPath: prefixPath, status: .idle)
        games.append(newGame)
        print("Imported game: \(suggestedName) with prefix: \(prefixPath)")
        return newGame
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
