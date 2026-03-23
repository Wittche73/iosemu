import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.frame = windowScene.coordinateSpace.bounds
        
        let contentView = LibraryView(core: CompatCoreDelegate())
        let hostingController = UIHostingController(rootView: contentView)
        
        window.rootViewController = hostingController
        self.window = window
        window.makeKeyAndVisible()
    }
}
