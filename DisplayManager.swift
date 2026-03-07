#if os(iOS)
import UIKit
#endif
import Foundation

/// Harici ekran (HDMI/AirPlay) ve Konsol Modu yönetimini sağlayan sınıf
class DisplayManager {
    static let shared = DisplayManager()
    
    #if os(iOS)
    private var externalWindow: UIWindow?
    #endif
    
    private init() {
        #if os(iOS)
        setupNotifications()
        #endif
    }
    
    #if os(iOS)
    private func setupNotifications() {
        NotificationCenter.default.addObserver(forName: UIScreen.didConnectNotification, object: nil, queue: .main) { notification in
            if let screen = notification.object as? UIScreen {
                self.setupExternalScreen(screen)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIScreen.didDisconnectNotification, object: nil, queue: .main) { _ in
            self.tearDownExternalScreen()
        }
    }
    
    func setupExternalScreen(_ screen: UIScreen) {
        print("📺 Harici ekran bağlandı: \(screen.bounds)")
        externalWindow = UIWindow(frame: screen.bounds)
        externalWindow?.screen = screen
        
        let controller = UIViewController()
        controller.view.backgroundColor = .black
        let label = UILabel()
        label.text = "Konsol Modu Aktif"
        label.textColor = .white
        label.sizeToFit()
        label.center = controller.view.center
        controller.view.addSubview(label)
        
        externalWindow?.rootViewController = controller
        externalWindow?.isHidden = false
        print("✅ DisplayManager: Oyun görüntüsü harici ekrana yönlendirildi.")
    }
    
    private func tearDownExternalScreen() {
        print("ℹ️ Harici ekran bağlantısı kesildi.")
        externalWindow = nil
    }
    #endif
    
    /// Şu an bir dış ekran bağlı mı?
    func isExternalDisplayConnected() -> Bool {
        #if os(iOS)
        return UIScreen.screens.count > 1
        #else
        return false // Simülatör/Linux için varsayılan
        #endif
    }
}
