import Foundation
import UIKit

/// iOS sistem hafıza baskısı (Low Memory) durumlarını dinleyen ve emülatörü stabilize eden sınıf
class MemoryPressureManager {
    static let shared = MemoryPressureManager()
    
    private init() {}
    
    /// Hafıza izleyicisini başlatır
    func startMonitoring() {
        print("--- MemoryPressureManager: Monitoring iOS System Memory Events ---")
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleLowMemory()
        }
    }
    
    /// Hafıza düşük uyarısı geldiğinde çalışacak mantık
    private func handleLowMemory() {
        print("⚠️ [CRITICAL] MemoryPressure: iOS Low Memory Warning Received!")
        
        // 1. Box64 DynaRec Cache'ini temizle (C++ Bridge üzerinden)
        // Not: Bu fonksiyonu RuntimeBridge.cpp tarafında implement edeceğiz.
        flushEmulatorCaches()
        
        // 2. Swift tarafındaki gereksiz önbellekleri temizle
        ShaderCacheManager.shared.clearCache()
        
        print("✅ MemoryPressure: Emergency cache flush completed. Stability prioritized.")
    }
    
    private func flushEmulatorCaches() {
        // C++ Bridge üzerinden Box64 DynaRec cache'ini acil durumda boşalt
        flush_dynarec_cache()
        print("   -> Requesting Box64 DynaRec cache flush via C bridge.")
    }
}
