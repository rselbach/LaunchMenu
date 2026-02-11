import AppKit
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuController: MenuController?
    private var hotKeyManager: HotKeyManager?
    private let settings = AppSettingsStore.shared
    private var updaterController: SPUStandardUpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        SettingsWindowController.shared.setUpdater(updaterController?.updater)
        settings.applyStartAtLoginSetting()
        menuController = MenuController(updater: updaterController?.updater)
        hotKeyManager = HotKeyManager()
    }
}
