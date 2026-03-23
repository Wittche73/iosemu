import Foundation

// Test senaryosu
func runTests() {
    print("--- LocalCompat Swift Test Başladı ---")
    
    let core = CompatCore()
    
    // 1. Oyun ice aktarma testi
    let game = core.importGame(from: "/games/gta_vc.exe", suggestedName: "GTA Vice City")
    assert(game.name == "GTA Vice City", "Oyun ismi hatalı!")
    print("✅ Oyun içe aktarma testi başarılı.")
    
    // 2. Oyun baslatma testi
    core.launchGame(id: game.id)
    // Not: Durum kontrolü için daha karmaşık bir yapı gerekebilir ama şimdilik iskelet testi.
    print("✅ Oyun başlatma iskelet testi başarılı.")
    
    // 3. Log çekme testi
    let logs = core.fetchLogs(for: game.id)
    assert(!logs.isEmpty, "Loglar boş olmamalı!")
    print("✅ Log sistemi testi başarılı.")
    
    print("--- Tüm Testler Başarıyla Tamamlandı ---")
}

runTests()
