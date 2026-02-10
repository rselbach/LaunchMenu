import AppKit

@MainActor
final class SettingsViewController: NSViewController {
    private let store: AppMappingsStore
    private var tableView = NSTableView()

    init(store: AppMappingsStore = .shared) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        tableView = NSTableView()
        tableView.headerView = nil
        tableView.rowHeight = 44
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.delegate = self
        tableView.dataSource = self

        let keyColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("key"))
        keyColumn.title = "Key"
        keyColumn.width = 120
        keyColumn.minWidth = 120
        tableView.addTableColumn(keyColumn)

        let appColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        appColumn.title = "Application"
        appColumn.width = 320
        appColumn.minWidth = 280
        tableView.addTableColumn(appColumn)

        scrollView.documentView = tableView

        let helpLabel = NSTextField(labelWithString: "Assign an app to each Function key for quick launch.")
        helpLabel.font = NSFont.systemFont(ofSize: 13)
        helpLabel.textColor = .secondaryLabelColor
        helpLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(helpLabel)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            helpLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            helpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            helpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: helpLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
        ])
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        tableView.reloadData()
    }
}

extension SettingsViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        FunctionKey.allCases.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let key = FunctionKey.allCases[safe: row] else {
            return nil
        }

        guard let tableColumn = tableColumn else {
            return nil
        }

        switch tableColumn.identifier.rawValue {
        case "key":
            let label = NSTextField(labelWithString: key.label)
            label.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
            label.alignment = .left
            label.textColor = .labelColor
            return label
        case "app":
            return appCell(for: key)
        default:
            return nil
        }
    }

    private func appCell(for key: FunctionKey) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = NSTextField(labelWithString: appName(for: key))
        nameLabel.font = NSFont.systemFont(ofSize: 13)
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.textColor = .labelColor
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let chooseButton = NSButton(title: "Choose...", target: self, action: #selector(chooseApp(_:)))
        chooseButton.tag = key.rawValue
        chooseButton.bezelStyle = .rounded
        chooseButton.translatesAutoresizingMaskIntoConstraints = false

        let clearButton = NSButton(title: "Clear", target: self, action: #selector(clearApp(_:)))
        clearButton.tag = key.rawValue
        clearButton.bezelStyle = .rounded
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.isEnabled = store.loadMappings().contains { $0.functionKey == key }

        container.addSubview(nameLabel)
        container.addSubview(chooseButton)
        container.addSubview(clearButton)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: chooseButton.leadingAnchor, constant: -8),

            clearButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),

            chooseButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chooseButton.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -8),
        ])

        return container
    }

    private func appName(for key: FunctionKey) -> String {
        guard let mapping = store.loadMappings().first(where: { $0.functionKey == key }) else {
            return "Not assigned"
        }

        return store.resolvedAppName(for: mapping.appPath)
    }

    @objc private func chooseApp(_ sender: NSButton) {
        guard let key = FunctionKey(rawValue: sender.tag) else {
            return
        }

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.prompt = "Select"

        panel.beginSheetModal(for: view.window ?? NSApp.keyWindow ?? NSWindow()) { [weak self] response in
            guard response == .OK, let url = panel.url else {
                return
            }

            self?.updateMapping(for: key, with: url.path)
        }
    }

    @objc private func clearApp(_ sender: NSButton) {
        guard let key = FunctionKey(rawValue: sender.tag) else {
            return
        }

        var mappings = store.loadMappings()
        mappings.removeAll { $0.functionKey == key }
        store.saveMappings(mappings)
        tableView.reloadData()
    }

    private func updateMapping(for key: FunctionKey, with path: String) {
        var mappings = store.loadMappings()
        if let index = mappings.firstIndex(where: { $0.functionKey == key }) {
            mappings[index] = AppMapping(functionKey: key, appPath: path)
        } else {
            mappings.append(AppMapping(functionKey: key, appPath: path))
        }

        store.saveMappings(mappings)
        tableView.reloadData()
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else {
            return nil
        }

        return self[index]
    }
}
