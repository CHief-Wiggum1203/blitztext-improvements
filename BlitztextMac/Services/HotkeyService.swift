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
    case down(WorkflowType)  // Keys pressed
    case up(WorkflowType)    // Keys released (for hold mode)
    case cancel              // Escape pressed
}

@Observable
@MainActor
final class HotkeyService {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var keyMonitor: Any?
    private var activeCombo: WorkflowType?  // Which combo is currently held

    var onHotkeyEvent: ((HotkeyEvent) -> Void)?

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in
                self?.handleFlags(event)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in
                self?.handleFlags(event)
            }
            return event
        }
        // Escape key monitor for toggle mode
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                if event.keyCode == 53 { // Escape
                    self?.handleEscape()
                }
            }
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        globalMonitor = nil
        localMonitor = nil
        keyMonitor = nil
    }

    private func handleFlags(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // fn + Shift + Control -> local transcription
        if flags == [.function, .shift, .control] {
            if activeCombo == nil {
                activeCombo = .localTranscription
                onHotkeyEvent?(.down(.localTranscription))
            }
            return
        }

        // fn + Shift -> transcription
        if flags == [.function, .shift] {
            if activeCombo == nil {
                activeCombo = .transcription
                onHotkeyEvent?(.down(.transcription))
            }
            return
        }

        // fn + Control -> Textverbesserer
        if flags == [.function, .control] {
            if activeCombo == nil {
                activeCombo = .textImprover
                onHotkeyEvent?(.down(.textImprover))
            }
            return
        }

        // fn + Option -> Rage Mode
        if flags == [.function, .option] {
            if activeCombo == nil {
                activeCombo = .dampfAblassen
                onHotkeyEvent?(.down(.dampfAblassen))
            }
            return
        }

        // fn + Command -> Emoji Mode
        if flags == [.function, .command] {
            if activeCombo == nil {
                activeCombo = .emojiText
                onHotkeyEvent?(.down(.emojiText))
            }
            return
        }

        // Keys released -- fire up event
        if let combo = activeCombo {
            activeCombo = nil
            onHotkeyEvent?(.up(combo))
        }
    }

    private func handleEscape() {
        activeCombo = nil
        onHotkeyEvent?(.cancel)
    }
}
