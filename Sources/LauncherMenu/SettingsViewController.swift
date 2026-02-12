import AppKit
import Sparkle

@MainActor
final class SettingsViewController: NSViewController {
    private let store: AppMappingsStore
    private let settings: AppSettingsStore
    private var updater: SPUUpdater?
    private var tableView = NSTableView()
    private var optionsView = NSView()
    private var startAtLoginCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private var behaviorPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private var autoUpdateCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)

    init(store: AppMappingsStore = .shared, settings: AppSettingsStore = .shared, updater: SPUUpdater?) {
        self.store = store
        self.settings = settings
        self.updater = updater
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let tabView = NSTabView()
        tabView.translatesAutoresizingMaskIntoConstraints = false

        let generalItem = NSTabViewItem(identifier: "options")
        generalItem.label = "General"
        generalItem.view = buildOptionsView()

        let mappingsItem = NSTabViewItem(identifier: "mappings")
        mappingsItem.label = "Mappings"
        mappingsItem.view = buildMappingsView()

        tabView.addTabViewItem(generalItem)
        tabView.addTabViewItem(mappingsItem)

        view.addSubview(tabView)

        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            tabView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
        ])
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        tableView.reloadData()
        refreshOptions()
    }

    func setUpdater(_ updater: SPUUpdater?) {
        self.updater = updater
        if isViewLoaded {
            refreshOptions()
        }
    }

    private func buildMappingsView() -> NSView {
        let container = NSView()
        container.autoresizingMask = [.width, .height]

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

        container.addSubview(helpLabel)
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            helpLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            helpLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            helpLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: helpLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])

        return container
    }

    private func buildOptionsView() -> NSView {
        optionsView = NSView()
        optionsView.autoresizingMask = [.width, .height]

        let startLabel = NSTextField(labelWithString: "Start at login")
        startLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        startLabel.translatesAutoresizingMaskIntoConstraints = false

        startAtLoginCheckbox = NSButton(checkboxWithTitle: "Start LauncherMenu when I sign in", target: self, action: #selector(toggleStartAtLogin(_:)))
        startAtLoginCheckbox.translatesAutoresizingMaskIntoConstraints = false

        let behaviorLabel = NSTextField(labelWithString: "When app is already open")
        behaviorLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        behaviorLabel.translatesAutoresizingMaskIntoConstraints = false

        behaviorPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        behaviorPopup.translatesAutoresizingMaskIntoConstraints = false
        behaviorPopup.addItems(withTitles: AppLaunchBehavior.allCases.map { $0.title })
        behaviorPopup.target = self
        behaviorPopup.action = #selector(changeBehavior(_:))

        let updatesLabel = NSTextField(labelWithString: "Updates")
        updatesLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        updatesLabel.translatesAutoresizingMaskIntoConstraints = false

        autoUpdateCheckbox = NSButton(checkboxWithTitle: "Check for updates automatically", target: self, action: #selector(toggleAutomaticUpdates(_:)))
        autoUpdateCheckbox.translatesAutoresizingMaskIntoConstraints = false

        optionsView.addSubview(startLabel)
        optionsView.addSubview(startAtLoginCheckbox)
        optionsView.addSubview(behaviorLabel)
        optionsView.addSubview(behaviorPopup)
        optionsView.addSubview(updatesLabel)
        optionsView.addSubview(autoUpdateCheckbox)

        NSLayoutConstraint.activate([
            startLabel.topAnchor.constraint(equalTo: optionsView.topAnchor, constant: 24),
            startLabel.leadingAnchor.constraint(equalTo: optionsView.leadingAnchor, constant: 20),
            startLabel.trailingAnchor.constraint(equalTo: optionsView.trailingAnchor, constant: -20),

            startAtLoginCheckbox.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 8),
            startAtLoginCheckbox.leadingAnchor.constraint(equalTo: optionsView.leadingAnchor, constant: 20),
            startAtLoginCheckbox.trailingAnchor.constraint(equalTo: optionsView.trailingAnchor, constant: -20),

            behaviorLabel.topAnchor.constraint(equalTo: startAtLoginCheckbox.bottomAnchor, constant: 24),
            behaviorLabel.leadingAnchor.constraint(equalTo: optionsView.leadingAnchor, constant: 20),
            behaviorLabel.trailingAnchor.constraint(equalTo: optionsView.trailingAnchor, constant: -20),

            behaviorPopup.topAnchor.constraint(equalTo: behaviorLabel.bottomAnchor, constant: 8),
            behaviorPopup.leadingAnchor.constraint(equalTo: optionsView.leadingAnchor, constant: 20),

            updatesLabel.topAnchor.constraint(equalTo: behaviorPopup.bottomAnchor, constant: 24),
            updatesLabel.leadingAnchor.constraint(equalTo: optionsView.leadingAnchor, constant: 20),
            updatesLabel.trailingAnchor.constraint(equalTo: optionsView.trailingAnchor, constant: -20),

            autoUpdateCheckbox.topAnchor.constraint(equalTo: updatesLabel.bottomAnchor, constant: 8),
            autoUpdateCheckbox.leadingAnchor.constraint(equalTo: optionsView.leadingAnchor, constant: 20),
            autoUpdateCheckbox.trailingAnchor.constraint(equalTo: optionsView.trailingAnchor, constant: -20),
        ])

        return optionsView
    }

    private func refreshOptions() {
        startAtLoginCheckbox.state = settings.startAtLogin ? .on : .off
        if let index = AppLaunchBehavior.allCases.firstIndex(of: settings.launchBehavior) {
            behaviorPopup.selectItem(at: index)
        }

        autoUpdateCheckbox.isEnabled = updater != nil
        autoUpdateCheckbox.state = updater?.automaticallyChecksForUpdates == true ? .on : .off
    }

    @objc private func toggleStartAtLogin(_ sender: NSButton) {
        do {
            try settings.setStartAtLogin(sender.state == .on)
        } catch {
            sender.state = settings.startAtLogin ? .on : .off
            showAlert(message: "Unable to update login item", info: error.localizedDescription)
        }
    }

    @objc private func changeBehavior(_ sender: NSPopUpButton) {
        guard let index = sender.indexOfSelectedItem as Int?,
              let behavior = AppLaunchBehavior.allCases[safe: index] else {
            return
        }

        settings.setLaunchBehavior(behavior)
    }

    @objc private func toggleAutomaticUpdates(_ sender: NSButton) {
        updater?.automaticallyChecksForUpdates = sender.state == .on
    }

    private func showAlert(message: String, info: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = info
        alert.alertStyle = .warning
        alert.beginSheetModal(for: view.window ?? NSApp.keyWindow ?? NSWindow()) { _ in }
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

        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = appIcon(for: key)

        let chooseButton = NSButton(title: "Choose...", target: self, action: #selector(chooseApp(_:)))
        chooseButton.tag = key.rawValue
        chooseButton.bezelStyle = .rounded
        chooseButton.translatesAutoresizingMaskIntoConstraints = false

        let clearButton = NSButton(title: "Clear", target: self, action: #selector(clearApp(_:)))
        clearButton.tag = key.rawValue
        clearButton.bezelStyle = .rounded
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.isEnabled = store.loadMappings().contains { $0.functionKey == key }

        container.addSubview(iconView)
        container.addSubview(nameLabel)
        container.addSubview(chooseButton)
        container.addSubview(clearButton)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
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

    private func appIcon(for key: FunctionKey) -> NSImage? {
        guard let mapping = store.loadMappings().first(where: { $0.functionKey == key }) else {
            return nil
        }

        return store.resolvedAppIcon(for: mapping.appPath, size: 18)
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
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        let handlePanelResponse: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let url = panel.url else {
                return
            }

            self?.updateMapping(for: key, with: url.path)
        }

        if let window = view.window ?? NSApp.keyWindow {
            panel.beginSheetModal(for: window, completionHandler: handlePanelResponse)
        } else {
            panel.begin(completionHandler: handlePanelResponse)
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
