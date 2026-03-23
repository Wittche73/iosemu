#if canImport(UIKit)

import UIKit

public final class ImportGameViewController: UIViewController {
    private let runtimeHost: RuntimeHosting
    private let onImport: @MainActor () -> Void
    private let sourcePathField = UITextField()
    private let displayNameField = UITextField()

    public init(runtimeHost: RuntimeHosting, onImport: @escaping @MainActor () -> Void) {
        self.runtimeHost = runtimeHost
        self.onImport = onImport
        super.init(nibName: nil, bundle: nil)
        title = "Import Game"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        sourcePathField.placeholder = "Source path"
        sourcePathField.borderStyle = .roundedRect
        sourcePathField.autocapitalizationType = .none

        displayNameField.placeholder = "Display name"
        displayNameField.borderStyle = .roundedRect

        let importButton = UIButton(type: .system)
        importButton.configuration = .filled()
        importButton.configuration?.title = "Import"
        importButton.addTarget(self, action: #selector(importTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [sourcePathField, displayNameField, importButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    @objc
    private func importTapped() {
        guard let source = sourcePathField.text, source.isEmpty == false else {
            presentError("Provide a source path for the game folder or executable.")
            return
        }

        Task { @MainActor in
            do {
                let url = URL(fileURLWithPath: source)
                _ = try await runtimeHost.importGame(from: url, suggestedName: displayNameField.text)
                onImport()
                navigationController?.popViewController(animated: true)
            } catch {
                presentError(error.localizedDescription)
            }
        }
    }

    private func presentError(_ message: String) {
        let alert = UIAlertController(title: "Import Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
#endif
