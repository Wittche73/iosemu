import Foundation

func testJITBridge() {
    print("--- LocalCompat JIT Bridge Test Başladı ---")
    
    let core = CompatCore()
    let game = core.importGame(from: "/tmp/test.exe", suggestedName: "JIT Test Game")
    
    // Oyun başlatma ve JIT mesaj kontrolü
    print("Oyun başlatılıyor...")
    core.launchGame(id: game.id)
    
    let isAvailable = JITManager.shared.isJITAvailable()
    print("Sistem JIT Durumu: \(isAvailable ? "AKTİF" : "PASİF")")
    
    print("--- JIT Bridge Testleri Tamamlandı ---")
}

testJITBridge()
