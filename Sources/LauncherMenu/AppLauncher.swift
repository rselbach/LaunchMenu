import AppKit

@MainActor
final class AppLauncher {
    static let shared = AppLauncher()

    private init() {}

    func launchOrFocusApp(atPath path: String) {
        let url = URL(fileURLWithPath: path)
        if let bundle = Bundle(url: url),
           let bundleIdentifier = bundle.bundleIdentifier {
            let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
            if let runningApp = runningApps.first {
                if runningApp.isHidden {
                    runningApp.unhide()
                }

                if runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps]) {
                    return
                }
            }
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
}
