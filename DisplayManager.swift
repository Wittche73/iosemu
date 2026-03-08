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
        NotificationCenter.default.addObserver(forName: UIScene.willConnectNotification, object: nil, queue: .main) { notification in
            if let scene = notification.object as? UIWindowScene, scene.session.role == .windowExternalDisplayNonInteractive {
                self.setupExternalScreen(scene)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIScene.didDisconnectNotification, object: nil, queue: .main) { notification in
            if let scene = notification.object as? UIWindowScene, scene.session.role == .windowExternalDisplayNonInteractive {
                self.tearDownExternalScreen()
            }
        }
    }
    
    func setupExternalScreen(_ scene: UIWindowScene) {
        print("📺 Harici ekran bağlandı: \(scene.screen.bounds)")
        externalWindow = UIWindow(windowScene: scene)
        
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
        return UIApplication.shared.connectedScenes.contains { scene in
            guard let windowScene = scene as? UIWindowScene else { return false }
            return windowScene.session.role == .windowExternalDisplayNonInteractive
        }
        #else
        return false // Native platform default
        #endif
    }
}
