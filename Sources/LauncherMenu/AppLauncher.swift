import AppKit

@MainActor
final class AppLauncher {
    static let shared = AppLauncher()
    private let settings: AppSettingsStore

    init(settings: AppSettingsStore = .shared) {
        self.settings = settings
    }

    func launchOrFocusApp(atPath path: String) {
        let url = URL(fileURLWithPath: path)
        if settings.launchBehavior == .focusExisting,
           focusRunningAppIfNeeded(at: url) {
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { app, error in
            if let error = error {
                NSLog("Failed to launch app at \(path): \(error)")
                return
            }

            if let app {
                _ = app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            }
        }
    }

    private func focusRunningAppIfNeeded(at url: URL) -> Bool {
        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier else {
            return false
        }

        guard let runningApp = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first else {
            return false
        }

        if runningApp.isHidden {
            runningApp.unhide()
        }

        return runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }
}
