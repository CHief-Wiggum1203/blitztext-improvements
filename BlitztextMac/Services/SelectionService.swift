import AppKit
import CoreGraphics

enum SelectionServiceError: LocalizedError {
    case noSelection
    case clipboardUnavailable

    var errorDescription: String? {
        switch self {
        case .noSelection: return "Kein Text ausgewählt."
        case .clipboardUnavailable: return "Zwischenablage nicht verfügbar."
        }
    }
}

/// Reads currently selected text from the frontmost app by simulating Cmd+C
/// while preserving the user's existing clipboard contents.
@MainActor
enum SelectionService {
    /// Reads the current selection. Throws `SelectionServiceError.noSelection` if nothing was captured.
    static func readSelection() async throws -> String {
        let pasteboard = NSPasteboard.general

        // Snapshot current pasteboard contents
        let snapshot = captureSnapshot(pasteboard: pasteboard)

        // Mark the pasteboard so we can detect whether Cmd+C actually wrote new content
        let initialChangeCount = pasteboard.changeCount

        // Fire Cmd+C
        simulateCopy()

        // Wait briefly for the target app to copy
        // Poll changeCount with short sleeps so we react quickly when the copy lands
        let deadline = Date().addingTimeInterval(0.3)
        while pasteboard.changeCount == initialChangeCount && Date() < deadline {
            try await Task.sleep(nanoseconds: 15_000_000) // 15 ms
        }

        // Read whatever text is now on the pasteboard
        let copiedText = pasteboard.string(forType: .string)

        // Restore snapshot regardless of outcome
        restore(snapshot: snapshot, on: pasteboard)

        guard let copiedText, !copiedText.isEmpty else {
            throw SelectionServiceError.noSelection
        }
        return copiedText
    }

    // MARK: - Helpers

    private struct PasteboardSnapshot {
        let items: [(type: NSPasteboard.PasteboardType, data: Data)]
    }

    private static func captureSnapshot(pasteboard: NSPasteboard) -> PasteboardSnapshot {
        let types = pasteboard.types ?? []
        var items: [(NSPasteboard.PasteboardType, Data)] = []
        for type in types {
            if let data = pasteboard.data(forType: type) {
                items.append((type, data))
            }
        }
        return PasteboardSnapshot(items: items)
    }

    private static func restore(snapshot: PasteboardSnapshot, on pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        guard !snapshot.items.isEmpty else { return }
        pasteboard.declareTypes(snapshot.items.map { $0.type }, owner: nil)
        for (type, data) in snapshot.items {
            pasteboard.setData(data, forType: type)
        }
    }

    private static func simulateCopy() {
        let source = CGEventSource(stateID: .hidSystemState)
        // kVK_ANSI_C = 0x08
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
