import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        // Use SwiftUI LibraryView
        let contentView = LibraryView(core: CompatCoreDelegate())
        let hostingController = UIHostingController(rootView: contentView)
        
        window.rootViewController = hostingController
        self.window = window
        window.makeKeyAndVisible()
        
        // Start advanced infrastructure monitors
        MemoryPressureManager.shared.startMonitoring()
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}
