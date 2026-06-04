import SwiftUI

// MARK: - Inline hotkey recorder for a single custom workflow

struct CustomHotkeyRecorderInline: View {
    let workflowID: UUID
    var appState: AppState

    @State private var isRecording = false
    @State private var conflictWarning: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Tastenkürzel")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isRecording {
                    Text("Aufnehmen ...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 120, alignment: .trailing)
                    Button("Abbrechen") {
                        stopRecording()
                    }
                    .buttonStyle(.borderless)
                } else {
                    Text(currentLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 120, alignment: .trailing)
                    Button("Ändern") {
                        startRecording()
                    }
                    .buttonStyle(.borderless)
                }
            }

            if let warning = conflictWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var currentWorkflow: CustomWorkflow? {
        appState.appSettings.customWorkflows.first(where: { $0.id == workflowID })
    }

    private var bindingKey: String { "custom:\(workflowID.uuidString)" }

    private var currentLabel: String {
        currentWorkflow?.hotkey?.displayLabel ?? "–"
    }

    private func startRecording() {
        guard !isRecording else { return }
        conflictWarning = nil
        isRecording = true
        let key = bindingKey
        appState.hotkeyService.startRecording(for: key) { newBinding in
            isRecording = false

            // Conflict detection across built-ins and other custom workflows
            for (otherKey, binding) in appState.hotkeyService.bindings {
                if otherKey != key && binding == newBinding {
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

            // Save: write through the array element; AppState.didSet pushes to hotkeyService
            if let idx = appState.appSettings.customWorkflows.firstIndex(where: { $0.id == workflowID }) {
                appState.appSettings.customWorkflows[idx].hotkey = newBinding
            }
        }
    }

    private func stopRecording() {
        appState.hotkeyService.stopRecording()
        isRecording = false
        conflictWarning = nil
    }
}

// MARK: - Card-style editor row for one custom workflow

struct CustomWorkflowEditorRow: View {
    let workflowID: UUID
    var appState: AppState

    private static let symbolChoices: [String] = [
        "sparkles", "globe", "text.bubble", "wand.and.stars", "bolt",
        "pencil.and.outline", "checkmark.seal", "text.append",
        "arrow.right.doc.on.clipboard", "keyboard", "quote.bubble",
        "book", "paperplane", "envelope", "flag"
    ]

    var body: some View {
        if let idx = appState.appSettings.customWorkflows.firstIndex(where: { $0.id == workflowID }) {
            let binding = Binding<CustomWorkflow>(
                get: { appState.appSettings.customWorkflows[idx] },
                set: { appState.appSettings.customWorkflows[idx] = $0 }
            )

            VStack(alignment: .leading, spacing: 10) {
                // Header: symbol preview + name + delete
                HStack(spacing: 8) {
                    Image(systemName: binding.wrappedValue.symbolName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 18)

                    TextField("Name", text: binding.name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11.5, weight: .semibold))

                    Button {
                        deleteWorkflow()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.red.opacity(0.75))
                    }
                    .buttonStyle(SubtleButtonStyle())
                    .help("Workflow löschen")
                }

                // Prompt
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prompt")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    TextEditor(text: binding.systemPrompt)
                        .font(.system(size: 11))
                        .frame(height: 80)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5))
                        .overlay(alignment: .topLeading) {
                            if binding.wrappedValue.systemPrompt.isEmpty {
                                Text("z.B. \"Antworte sachlich und auf Deutsch.\"")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.quaternary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                // Mode + Model
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Modus")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Picker("", selection: binding.mode) {
                            ForEach(CustomWorkflowMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Modell")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Picker("", selection: binding.modelPreference) {
                            ForEach(ModelPreference.allCases) { pref in
                                Text(pref.displayName).tag(pref)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }

                // Symbol picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Symbol")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Picker("", selection: binding.symbolName) {
                        ForEach(Self.symbolChoices, id: \.self) { sym in
                            Label(sym, systemImage: sym).tag(sym)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                }

                // Hotkey
                CustomHotkeyRecorderInline(workflowID: workflowID, appState: appState)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
        } else {
            EmptyView()
        }
    }

    private func deleteWorkflow() {
        withAnimation(.easeOut(duration: 0.15)) {
            appState.appSettings.customWorkflows.removeAll { $0.id == workflowID }
        }
    }
}
