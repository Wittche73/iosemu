#if canImport(UIKit)

import UIKit

public final class GameLibraryViewController: UITableViewController {
    private let viewModel: GameLibraryViewModel
    private var games: [GameRecord] = []

    public init(viewModel: GameLibraryViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        title = "LocalCompat"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Import", style: .plain, target: self, action: #selector(importTapped)),
            UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refreshTapped)),
        ]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GameCell")
        loadGames()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        games.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath)
        let game = games[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = game.displayName
        content.secondaryText = "\(game.rendererMode.displayName) | \(game.lastResult.rawValue)"
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let game = games[indexPath.row]
        navigationController?.pushViewController(
            GameDetailViewController(game: game, runtimeHost: viewModel.runtimeHost),
            animated: true
        )
    }

    @objc
    private func refreshTapped() {
        loadGames()
    }

    @objc
    private func importTapped() {
        let controller = ImportGameViewController(runtimeHost: viewModel.runtimeHost) { [weak self] in
            self?.loadGames()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func loadGames() {
        Task { @MainActor in
            await viewModel.reload()
            games = viewModel.games
            tableView.reloadData()
            if let message = viewModel.lastErrorMessage {
                presentError(message)
            }
        }
    }

    private func presentError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
#endif
