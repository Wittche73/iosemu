#if canImport(UIKit)

import UIKit

public final class InputProfileViewController: UIViewController {
    private var game: GameRecord
    private let runtimeHost: RuntimeHosting
    private let gamepadSwitch = UISwitch()
    private let touchSwitch = UISwitch()

    public init(game: GameRecord, runtimeHost: RuntimeHosting) {
        self.game = game
        self.runtimeHost = runtimeHost
        super.init(nibName: nil, bundle: nil)
        title = "Input Profile"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        gamepadSwitch.isOn = game.inputProfile.gamepadEnabled
        touchSwitch.isOn = game.inputProfile.touchOverlayEnabled

        let rows = [
            makeRow(title: "Bluetooth Gamepad", control: gamepadSwitch),
            makeRow(title: "Touch Overlay", control: touchSwitch),
        ]

        let saveButton = UIButton(type: .system)
        saveButton.configuration = .filled()
        saveButton.configuration?.title = "Save"
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: rows + [saveButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    @objc
    private func saveTapped() {
        let profile = InputProfile(
            gamepadEnabled: gamepadSwitch.isOn,
            touchOverlayEnabled: touchSwitch.isOn,
            buttons: game.inputProfile.buttons
        )

        Task { @MainActor in
            do {
                game = try await runtimeHost.updateInputProfile(for: game.id, profile: profile)
                navigationController?.popViewController(animated: true)
            } catch {
                let alert = UIAlertController(title: "Save Failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func makeRow(title: String, control: UIView) -> UIView {
        let label = UILabel()
        label.text = title
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }
}
#endif
