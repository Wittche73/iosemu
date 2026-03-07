#if canImport(UIKit)
import CompatCore
import UIKit

public final class AppCoordinator {
    private let runtimeHost: RuntimeHosting

    public init(runtimeHost: RuntimeHosting) {
        self.runtimeHost = runtimeHost
    }

    public func makeRootViewController() -> UIViewController {
        let viewModel = GameLibraryViewModel(runtimeHost: runtimeHost)
        return UINavigationController(rootViewController: GameLibraryViewController(viewModel: viewModel))
    }
}
#endif
