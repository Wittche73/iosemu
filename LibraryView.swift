import SwiftUI

struct LibraryView: View {
    @ObservedObject var core: CompatCoreDelegate
    @State private var showingSettings = false
    @State private var selectedGame: Game?
    
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka Plan Gradiyenti
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(white: 0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("Oyun Kütüphanen")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            // Toplu Profil Uygulama / Güncelleme Butonu
                            Button(action: { /* Global Sync */ }) {
                                Image(systemName: "arrow.clockwise.icloud.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                            ForEach(core.games) { game in
                                VStack(spacing: 8) {
                                    GameCardView(game: game) {
                                        core.launchGame(id: game.id)
                                    }
                                    
                                    // Hazır Profil Uygulama Butonu
                                    if CommunityProfileManager.shared.getProfile(for: game.name) != nil {
                                        Button(action: {
                                            core.applyOptimizedProfile(for: game.id)
                                        }) {
                                            Label("En İyi Ayarlar", systemImage: "sparkles")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .padding(6)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(.blue)
                                                .clipShape(Capsule())
                                        }
                                    } else {
                                        // Yer Tutucu (Button olmadığında hizalamanın bozulmaması için)
                                        Spacer().frame(height: 28)
                                    }
                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                            }
                            
                            // Yeni Oyun Ekle Butonu
                            Button(action: { /* Oyun İçe Aktar */ }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    Text("Yeni Oyun")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(0.8, contentMode: .fill)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                        .foregroundColor(.white.opacity(0.2))
                                )
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // --- OYUN SIRASINDA GÖRÜNECEK KATMANLAR ---
                if core.games.contains(where: { $0.status == .running }) {
                    // 0. Oyun Render Katmanı (Metal)
                    MetalGameView()
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    // 1. Sanal Kontrolcü Overlay
                    VirtualControllerView()
                        .transition(.opacity)
                    
                    // 2. Performans Göstergesi (HUD)
                    PerformanceHUDView()
                        .transition(.move(edge: .top))
                    
                    // 3. Çıkış Butonu (Demo için)
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { core.stopAllGames() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { core.discoverGames() }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsDashboard()
            }
        }
        .navigationViewStyle(.stack)
    }
}

/// SwiftUI için CompatCore'un gözlemlenebilir versiyonu
class CompatCoreDelegate: ObservableObject {
    @Published var games: [Game] = []
    private let core = CompatCore()
    
    init() {
        // Test verileri
        games.append(core.importGame(from: "C:\\Games\\Doom.exe", suggestedName: "Doom Eternal"))
        games.append(core.importGame(from: "C:\\Games\\Skyrim.exe", suggestedName: "Skyrim"))
        games.append(core.importGame(from: "C:\\Games\\HL.exe", suggestedName: "Half-Life"))
    }
    
    func launchGame(id: UUID) {
        if let index = games.firstIndex(where: { $0.id == id }) {
            games[index].status = .running
            core.launchGame(id: id)
        }
    }
    
    func applyOptimizedProfile(for id: UUID) {
        if let index = games.firstIndex(where: { $0.id == id }) {
            var game = games[index]
            if CommunityProfileManager.shared.applyCommunityProfile(to: &game) {
                games[index] = game
                print("✨ \(game.name) için topluluk ayarları uygulandı.")
            }
        }
    }
    
    func stopAllGames() {
        for i in 0..<games.count {
            if games[i].status == .running {
                games[i].status = .idle
            }
        }
        DynamicJITManager.shared.stopMonitoring()
    }
    
    func discoverGames() {
        let newOnes = core.discoverGames()
        if !newOnes.isEmpty {
            // Basitçe listenin sonuna ekle veya tam yenile
            self.games = core.fetchGames() 
        }
    }
}
