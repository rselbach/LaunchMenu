import AppKit
import Carbon

final class HotKeyManager {
    private var hotKeys: [FunctionKey: EventHotKeyRef] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private let store: AppMappingsStore

    init(store: AppMappingsStore = .shared) {
        self.store = store
        registerEventHandler()
        registerHotKeys()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMappingsChange),
            name: AppMappingsStore.mappingsDidChangeNotification,
            object: nil
        )
    }

    deinit {
        unregisterHotKeys()
        unregisterEventHandler()
    }

    @objc private func handleMappingsChange() {
        registerHotKeys()
    }

    private func registerEventHandler() {
        var handler: EventHandlerRef?
        let callback: EventHandlerUPP = { _, eventRef, userData in
            guard let userData else {
                return OSStatus(eventNotHandledErr)
            }

            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handleHotKeyEvent(eventRef)
            return noErr
        }

        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            [eventType],
            Unmanaged.passUnretained(self).toOpaque(),
            &handler
        )

        guard status == noErr else {
            NSLog("Failed to install hotkey handler: \(status)")
            return
        }

        eventHandlerRef = handler
    }

    private func unregisterEventHandler() {
        guard let handler = eventHandlerRef else {
            return
        }

        let status = RemoveEventHandler(handler)
        if status != noErr {
            NSLog("Failed to remove hotkey handler: \(status)")
        }

        eventHandlerRef = nil
    }

    private func registerHotKeys() {
        unregisterHotKeys()

        let mappings = store.loadMappings()
        for mapping in mappings {
            registerHotKey(for: mapping.functionKey)
        }
    }

    private func unregisterHotKeys() {
        for (_, ref) in hotKeys {
            UnregisterEventHotKey(ref)
        }

        hotKeys.removeAll()
    }

    private func registerHotKey(for key: FunctionKey) {
        guard let keyCode = HotKeyManager.keyCode(for: key) else {
            return
        }

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(HotKeyManager.signature), id: UInt32(key.rawValue))
        let status = RegisterEventHotKey(
            keyCode,
            0,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let hotKeyRef {
            hotKeys[key] = hotKeyRef
        } else if status != noErr {
            NSLog("Failed to register hotkey for \(key.label): \(status)")
        }
    }

    private func handleHotKeyEvent(_ eventRef: EventRef?) {
        guard let eventRef else {
            return
        }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else {
            NSLog("Failed to read hotkey event: \(status)")
            return
        }

        guard hotKeyID.signature == HotKeyManager.signature,
              let key = FunctionKey(rawValue: Int(hotKeyID.id)) else {
            return
        }

        launchApp(for: key)
    }

    private func launchApp(for key: FunctionKey) {
        guard let mapping = store.loadMappings().first(where: { $0.functionKey == key }) else {
            return
        }

        let path = mapping.appPath
        Task { @MainActor in
            AppLauncher.shared.launchOrFocusApp(atPath: path)
        }
    }

    private static let signature: FourCharCode = 0x4C4D464B

    private static func keyCode(for key: FunctionKey) -> UInt32? {
        switch key {
        case .f1:
            return UInt32(kVK_F1)
        case .f2:
            return UInt32(kVK_F2)
        case .f3:
            return UInt32(kVK_F3)
        case .f4:
            return UInt32(kVK_F4)
        case .f5:
            return UInt32(kVK_F5)
        case .f6:
            return UInt32(kVK_F6)
        case .f7:
            return UInt32(kVK_F7)
        case .f8:
            return UInt32(kVK_F8)
        case .f9:
            return UInt32(kVK_F9)
        case .f10:
            return UInt32(kVK_F10)
        case .f11:
            return UInt32(kVK_F11)
        case .f12:
            return UInt32(kVK_F12)
        }
    }
}
