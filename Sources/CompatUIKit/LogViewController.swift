#if canImport(UIKit)
import CompatCore
import UIKit

public final class LogViewController: UIViewController {
    private let gameID: UUID
    private let runtimeHost: RuntimeHosting
    private let textView = UITextView()

    public init(gameID: UUID, runtimeHost: RuntimeHosting) {
        self.gameID = gameID
        self.runtimeHost = runtimeHost
        super.init(nibName: nil, bundle: nil)
        title = "Logs"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        loadLogs()
    }

    private func loadLogs() {
        Task { @MainActor in
            do {
                textView.text = try await runtimeHost.fetchLogs(for: gameID)
            } catch {
                textView.text = error.localizedDescription
            }
        }
    }
}
#endif
