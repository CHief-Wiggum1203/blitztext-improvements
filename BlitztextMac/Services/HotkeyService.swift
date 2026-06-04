import Cocoa
import Observation

struct HotkeyBinding: Codable, Equatable {
    var keyCode: UInt16       // 0xFFFF = no regular key (modifier-only combo)
    var modifierFlags: UInt   // NSEvent.ModifierFlags.rawValue

    private enum CodingKeys: String, CodingKey {
        case keyCode
        case modifierFlags
    }

    var nsModifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlags)
    }

    var displayLabel: String {
        if keyCode == 0xFFFF {
            return HotkeyBinding.modifierOnlyLabel(nsModifierFlags)
        } else {
            return HotkeyBinding.keyLabel(keyCode, modifiers: nsModifierFlags)
        }
    }

    static func modifierOnlyLabel(_ flags: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if flags.contains(.function) { parts.append("fn") }
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        return parts.joined(separator: " ")
    }

    static func keyLabel(_ keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if modifiers.contains(.function) { parts.append("fn") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        if keyCode != 0xFFFF { parts.append(keyName(for: keyCode)) }
        return parts.joined(separator: " ")
    }

    private static let keyNameMap: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 25: "9", 26: "7", 28: "8", 29: "0",
        31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
        38: "J", 40: "K", 45: "N", 46: "M",
        49: "Space", 51: "⌫", 123: "←", 124: "→", 125: "↓", 126: "↑"
    ]

    private static func keyName(for keyCode: UInt16) -> String {
        return keyNameMap[keyCode] ?? "?"
    }
}

extension HotkeyBinding {
    static let defaults: [WorkflowType: HotkeyBinding] = [
        .transcription: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.shift).rawValue
        ),
        .localTranscription: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.shift).union(.control).rawValue
        ),
        .textImprover: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.control).rawValue
        ),
        .dampfAblassen: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.option).rawValue
        ),
        .emojiText: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.command).rawValue
        ),
    ]
}

enum HotkeyMode: String, Codable, CaseIterable, Identifiable {
    case hold    // Tasten halten = aufnehmen, loslassen = stoppen
    case toggle  // Einmal drücken = starten, nochmal/Escape = stoppen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hold: return "Halten"
        case .toggle: return "Drücken"
        }
    }

    var description: String {
        switch self {
        case .hold: return "Tasten halten zum Aufnehmen, loslassen zum Stoppen"
        case .toggle: return "Einmal drücken zum Starten, nochmal oder Escape zum Stoppen"
        }
    }
}

enum HotkeyEvent {
    case down(String)  // Keys pressed; id is WorkflowType.rawValue or "custom:<uuid>"
    case up(String)    // Keys released (for hold mode)
    case cancel        // Escape pressed
}

@Observable
@MainActor
final class HotkeyService {
    var bindings: [String: HotkeyBinding] = HotkeyBinding.defaults
        .reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }

    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var globalKeyDownMonitor: Any?
    private var globalKeyUpMonitor: Any?
    private var activeCombo: String?
    private var lastRecordedFlags: NSEvent.ModifierFlags = []

    // Recording state
    private var recordingFor: String?
    private var recordingCompletion: ((HotkeyBinding) -> Void)?

    var onHotkeyEvent: ((HotkeyEvent) -> Void)?

    func start() {
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in self?.handleFlags(event) }
        }
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in self?.handleFlags(event) }
            return event
        }
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in self?.handleKeyDown(event) }
        }
        globalKeyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            Task { @MainActor in self?.handleKeyUp(event) }
        }
    }

    func stop() {
        [globalFlagsMonitor, localFlagsMonitor, globalKeyDownMonitor, globalKeyUpMonitor]
            .compactMap { $0 }
            .forEach { NSEvent.removeMonitor($0) }
        globalFlagsMonitor = nil
        localFlagsMonitor = nil
        globalKeyDownMonitor = nil
        globalKeyUpMonitor = nil
    }

    func updateBindings(_ newBindings: [String: HotkeyBinding]) {
        self.bindings = newBindings
    }

    func startRecording(for id: String, completion: @escaping (HotkeyBinding) -> Void) {
        recordingFor = id
        recordingCompletion = completion
    }

    func stopRecording() {
        recordingFor = nil
        recordingCompletion = nil
        lastRecordedFlags = []
    }

    private func handleFlags(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Recording mode: capture modifier combo on release
        if recordingFor != nil {
            if !flags.isEmpty {
                lastRecordedFlags = flags
            } else if !lastRecordedFlags.isEmpty {
                let captured = lastRecordedFlags
                lastRecordedFlags = []
                let binding = HotkeyBinding(keyCode: 0xFFFF, modifierFlags: captured.rawValue)
                recordingFor = nil
                let completion = recordingCompletion
                recordingCompletion = nil
                completion?(binding)
            }
            return
        }

        // Normal mode: match modifier-only bindings
        for (id, binding) in bindings where binding.keyCode == 0xFFFF {
            if flags == binding.nsModifierFlags {
                guard activeCombo == nil else { return }
                activeCombo = id
                onHotkeyEvent?(.down(id))
                return
            }
        }

        // Release: fire up event for active modifier-only combo
        if let combo = activeCombo, bindings[combo]?.keyCode == 0xFFFF {
            activeCombo = nil
            onHotkeyEvent?(.up(combo))
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        let keyCode = event.keyCode

        // Escape: cancel
        guard keyCode != 53 else {
            handleEscape()
            return
        }

        // Recording mode: capture key+modifier combo
        if recordingFor != nil {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let binding = HotkeyBinding(keyCode: keyCode, modifierFlags: flags.rawValue)
            recordingFor = nil
            let completion = recordingCompletion
            recordingCompletion = nil
            lastRecordedFlags = []
            completion?(binding)
            return
        }

        // Normal mode: match key+modifier bindings
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        for (id, binding) in bindings where binding.keyCode != 0xFFFF {
            guard keyCode == binding.keyCode,
                  flags == binding.nsModifierFlags,
                  activeCombo == nil else { continue }
            activeCombo = id
            onHotkeyEvent?(.down(id))
            return
        }
    }

    private func handleKeyUp(_ event: NSEvent) {
        guard let combo = activeCombo,
              let binding = bindings[combo],
              binding.keyCode != 0xFFFF,
              event.keyCode == binding.keyCode else { return }
        activeCombo = nil
        onHotkeyEvent?(.up(combo))
    }

    private func handleEscape() {
        activeCombo = nil
        onHotkeyEvent?(.cancel)
    }
}
