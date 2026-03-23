import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

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

    func applicationDidEnterBackground(_ application: UIApplication) {
        startBackgroundTask()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        endBackgroundTask()
    }
    
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
        print("--- AppDelegate: Background Task Started [\(backgroundTask.rawValue)] ---")
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            print("--- AppDelegate: Background Task Ended ---")
        }
    }
}
