import AppKit
import Foundation

final class AppMappingsStore: @unchecked Sendable {
    static let shared = AppMappingsStore()

    static let mappingsDidChangeNotification = Notification.Name("AppMappingsStore.mappingsDidChange")

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let defaultsKey = "appMappings"

    private init() {}

    func loadMappings() -> [AppMapping] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            return []
        }

        do {
            return try decoder.decode([AppMapping].self, from: data)
        } catch {
            NSLog("Failed to decode mappings: \(error)")
            return []
        }
    }

    func saveMappings(_ mappings: [AppMapping]) {
        do {
            let data = try encoder.encode(mappings)
            UserDefaults.standard.set(data, forKey: defaultsKey)
            NotificationCenter.default.post(name: Self.mappingsDidChangeNotification, object: nil)
        } catch {
            NSLog("Failed to encode mappings: \(error)")
        }
    }

    func resolvedAppName(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return FileManager.default.displayName(atPath: url.path)
    }

    func resolvedAppIcon(for path: String, size: CGFloat = 16) -> NSImage? {
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }

        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: size, height: size)
        icon.isTemplate = false
        return icon
    }
}
