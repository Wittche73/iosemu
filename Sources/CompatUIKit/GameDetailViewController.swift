#if canImport(UIKit)
import CompatCore
import UIKit

public final class GameDetailViewController: UIViewController {
    private var game: GameRecord
    private let runtimeHost: RuntimeHosting
    private let stackView = UIStackView()

    public init(game: GameRecord, runtimeHost: RuntimeHosting) {
        self.game = game
        self.runtimeHost = runtimeHost
        super.init(nibName: nil, bundle: nil)
        title = game.displayName
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
        render()
    }

    private func render() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        stackView.addArrangedSubview(makeLabel("Executable: \(game.executableName)"))
        stackView.addArrangedSubview(makeLabel("Renderer: \(game.rendererMode.displayName)"))
        stackView.addArrangedSubview(makeLabel("Prefix: \(game.prefixRelativePath)"))
        stackView.addArrangedSubview(makeLabel("Result: \(game.lastResult.rawValue)"))
        stackView.addArrangedSubview(makeButton(title: "Launch", action: #selector(launchTapped)))
        stackView.addArrangedSubview(makeButton(title: "Stop", action: #selector(stopTapped)))
        stackView.addArrangedSubview(makeButton(title: "Input Profile", action: #selector(inputTapped)))
        stackView.addArrangedSubview(makeButton(title: "Logs", action: #selector(logsTapped)))
    }

    @objc
    private func launchTapped() {
        Task { @MainActor in
            do {
                try await runtimeHost.launchGame(id: game.id)
                try await refreshGame()
            } catch {
                presentError(error.localizedDescription)
            }
        }
    }

    @objc
    private func stopTapped() {
        Task { @MainActor in
            do {
                try await runtimeHost.stopGame(id: game.id)
                try await refreshGame()
            } catch {
                presentError(error.localizedDescription)
            }
        }
    }

    @objc
    private func logsTapped() {
        navigationController?.pushViewController(LogViewController(gameID: game.id, runtimeHost: runtimeHost), animated: true)
    }

    @objc
    private func inputTapped() {
        navigationController?.pushViewController(InputProfileViewController(game: game, runtimeHost: runtimeHost), animated: true)
    }

    private func refreshGame() async throws {
        if let updated = (try await runtimeHost.listGames()).first(where: { $0.id == game.id }) {
            game = updated
        }
        render()
    }

    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        return label
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.configuration = .filled()
        button.configuration?.title = title
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func presentError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
#endif
