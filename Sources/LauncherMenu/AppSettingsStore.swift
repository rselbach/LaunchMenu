import AppKit
import ServiceManagement
import os

enum AppLaunchBehavior: String, CaseIterable {
    case focusExisting
    case launchNewInstance

    var title: String {
        switch self {
        case .focusExisting:
            return "Focus existing app"
        case .launchNewInstance:
            return "Launch new instance"
        }
    }
}

final class AppSettingsStore: @unchecked Sendable {
    static let shared = AppSettingsStore()

    private let defaults = UserDefaults.standard
    private let logger = Logger(subsystem: "LauncherMenu", category: "AppSettings")
    private let launchBehaviorKey = "launchBehavior"
    private let startAtLoginKey = "startAtLogin"

    private init() {
        if defaults.object(forKey: startAtLoginKey) == nil {
            let status = SMAppService.mainApp.status
            let shouldStart = status == .enabled || status == .requiresApproval
            defaults.set(shouldStart, forKey: startAtLoginKey)
        }
    }

    var launchBehavior: AppLaunchBehavior {
        guard let rawValue = defaults.string(forKey: launchBehaviorKey),
              let behavior = AppLaunchBehavior(rawValue: rawValue) else {
            return .focusExisting
        }

        return behavior
    }

    var startAtLogin: Bool {
        defaults.bool(forKey: startAtLoginKey)
    }

    func setLaunchBehavior(_ behavior: AppLaunchBehavior) {
        defaults.set(behavior.rawValue, forKey: launchBehaviorKey)
    }

    func setStartAtLogin(_ enabled: Bool) throws {
        let service = SMAppService.mainApp
        if enabled {
            if service.status != .enabled {
                try service.register()
            }
        } else if service.status == .enabled || service.status == .requiresApproval {
            try service.unregister()
        }

        defaults.set(enabled, forKey: startAtLoginKey)
    }

    func applyStartAtLoginSetting() {
        do {
            try setStartAtLogin(startAtLogin)
        } catch {
            logger.error("Failed to sync login item: \(error.localizedDescription)")
        }
    }
}
