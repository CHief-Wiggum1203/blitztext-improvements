import SwiftUI

struct HotkeyRecorderRow: View {
    let workflowType: WorkflowType
    var appState: AppState

    @State private var isRecording = false
    @State private var conflictWarning: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Row layout:
            // [WorkflowType.displayName]    [current label OR "Aufnehmen..."]    [Ändern / Abbrechen]
            HStack {
                Text(workflowType.displayName)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isRecording {
                    Text("Aufnehmen ...")
                        .foregroundColor(.secondary)
                        .frame(minWidth: 120, alignment: .trailing)
                    Button("Abbrechen") {
                        stopRecording()
                    }
                    .buttonStyle(.borderless)
                } else {
                    Text(currentLabel)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 120, alignment: .trailing)
                    Button("Ändern") {
                        startRecording()
                    }
                    .buttonStyle(.borderless)
                }
            }

            // Show conflict warning below the row if present
            if let warning = conflictWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var currentLabel: String {
        appState.appSettings.hotkeyBindings[workflowType.rawValue]?.displayLabel
            ?? HotkeyBinding.defaults[workflowType]?.displayLabel
            ?? "–"
    }

    private func startRecording() {
        guard !isRecording else { return }
        conflictWarning = nil
        isRecording = true
        appState.hotkeyService.startRecording(for: workflowType.rawValue) { newBinding in
            isRecording = false
            // Conflict detection: check if this combo is used by another workflow (built-in or custom)
            for (otherKey, binding) in appState.hotkeyService.bindings {
                if otherKey != workflowType.rawValue && binding == newBinding {
                    if let other = WorkflowType(rawValue: otherKey) {
                        conflictWarning = "Bereits belegt von: \(other.displayName)"
                    } else if let uuid = CustomWorkflow.parseHotkeyBindingKey(otherKey),
                              let cw = appState.appSettings.customWorkflows.first(where: { $0.id == uuid }) {
                        conflictWarning = "Bereits belegt von: \(cw.name)"
                    } else {
                        conflictWarning = "Bereits belegt."
                    }
                    return
                }
            }
            // Save: update hotkeyBindings and let AppState.didSet push to hotkeyService
            var updated = appState.appSettings.hotkeyBindings
            updated[workflowType.rawValue] = newBinding
            appState.appSettings.hotkeyBindings = updated
        }
    }

    private func stopRecording() {
        appState.hotkeyService.stopRecording()
        isRecording = false
        conflictWarning = nil
    }
}
