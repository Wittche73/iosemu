import SwiftUI

/// Oyun sırasında FPS, CPU ve DynaRec istatistiklerini gösteren HUD
struct PerformanceHUDView: View {
    @State private var stats: EngineStats = EngineStats()
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 12) {
                        StatItem(label: "FPS", value: "60", color: .green)
                        StatItem(label: "JIT HIT", value: "\(stats.hits)", color: .blue)
                        StatItem(label: "MISS", value: "\(stats.misses)", color: .red)
                    }
                    
                    HStack(spacing: 12) {
                        StatItem(label: "CACHE", value: "\(stats.cacheUsage)MB", color: .purple)
                        StatItem(label: "HEALTH", value: stats.health, color: .orange)
                    }
                }
                .padding(10)
                .background(BlurView(style: .systemThinMaterialDark))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .padding()
            }
            Spacer()
        }
        .onAppear {
            startUpdating()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startUpdating() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            updateStats()
        }
    }
    
    private func updateStats() {
        // C++ Bridge'den gerçek verileri çek
        let jsonStr = String(cString: get_engine_stats())
        if let data = jsonStr.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode(EngineStats.self, from: data) {
                self.stats = decoded
            }
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

struct EngineStats: Codable {
    var hits: Int = 0
    var misses: Int = 0
    var cacheUsage: Int = 0
    var health: String = "OK"
    
    enum CodingKeys: String, CodingKey {
        case hits, misses, health
        case cacheUsage = "cache_usage"
    }
}
