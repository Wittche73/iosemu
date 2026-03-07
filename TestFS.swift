import Foundation

func testFilesystem() {
    print("--- LocalCompat Filesystem Test Başladı ---")
    
    let core = CompatCore()
    
    // 1. Oyun ice aktarma ve prefix oluşturma testi
    let game = core.importGame(from: "/tmp/test_game.exe", suggestedName: "Test Game")
    
    assert(!game.prefixPath.isEmpty, "Prefix yolu boş olmamalı!")
    assert(game.prefixPath.contains(game.id.uuidString), "Prefix yolu oyun ID'sini içermeli!")
    
    print("✅ Prefix oluşturma testi başarılı.")
    
    // 2. Dizin yapısı kontrolü (simüle edilen ortamda klasörleri kontrol edelim)
    let driveC = URL(fileURLWithPath: game.prefixPath).appendingPathComponent("drive_c")
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: driveC.path, isDirectory: &isDir) {
        assert(isDir.boolValue, "drive_c bir dizin olmalı!")
        print("✅ drive_c dizin kontrolü başarılı.")
    } else {
        print("❌ drive_c dizini bulunamadı!")
    }
    
    print("--- Filesystem Testleri Tamamlandı ---")
}

testFilesystem()
