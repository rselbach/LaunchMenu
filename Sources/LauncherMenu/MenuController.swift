import AppKit

@MainActor
final class MenuController: NSObject {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let store: AppMappingsStore

    init(store: AppMappingsStore = .shared) {
        self.store = store
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        statusItem.button?.image = NSImage(systemSymbolName: "command", accessibilityDescription: "Launcher Menu")
        statusItem.menu = menu

        rebuildMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMappingsChange),
            name: AppMappingsStore.mappingsDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleMappingsChange() {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let mappings = store.loadMappings()
        let mappingByKey = Dictionary(uniqueKeysWithValues: mappings.map { ($0.functionKey, $0) })

        for key in FunctionKey.allCases {
            guard let mapping = mappingByKey[key] else {
                continue
            }

            let item = NSMenuItem()
            let appName = store.resolvedAppName(for: mapping.appPath)
            item.title = "\(key.label) \u{2022} \(appName)"
            item.image = store.resolvedAppIcon(for: mapping.appPath)
            item.representedObject = mapping.appPath
            item.target = self
            item.action = #selector(launchApp(_:))
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit LauncherMenu", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func launchApp(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }

        AppLauncher.shared.launchOrFocusApp(atPath: path)
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showWindow(nil)
        SettingsWindowController.shared.window?.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
