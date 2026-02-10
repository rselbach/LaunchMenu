import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuController: MenuController?
    private var hotKeyManager: HotKeyManager?
    private let settings = AppSettingsStore.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.applyStartAtLoginSetting()
        menuController = MenuController()
        hotKeyManager = HotKeyManager()
    }
}
