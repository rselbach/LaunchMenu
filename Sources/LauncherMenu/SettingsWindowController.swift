import AppKit
import Sparkle

@MainActor
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    private let viewController: SettingsViewController

    private init() {
        viewController = SettingsViewController(updater: nil)
        let window = NSWindow(contentViewController: viewController)
        window.title = "LauncherMenu Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 560))
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.collectionBehavior = [.fullScreenAuxiliary]

        super.init(window: window)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }

    func setUpdater(_ updater: SPUUpdater?) {
        viewController.setUpdater(updater)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func windowDidClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
