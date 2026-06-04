import SwiftUI

struct CustomWorkflowRowView: View {
    let customWorkflow: CustomWorkflow
    let enabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with monochrome background, mirrors WorkflowRowView
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(isHovered ? 0.1 : 0.06))
                        .frame(width: 36, height: 36)

                    Image(systemName: customWorkflow.symbolName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                // Name + subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(customWorkflow.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(enabled ? .primary : .tertiary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(enabled ? .secondary : .quaternary)
                        .lineLimit(1)
                }

                Spacer()

                // Hotkey badge (only when a hotkey is set)
                if let label = customWorkflow.hotkey?.displayLabel, !label.isEmpty {
                    HotkeyBadge(label: label, enabled: enabled)
                        .opacity(enabled ? 1 : 0.4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered && enabled ? Color.primary.opacity(0.05) : Color.clear)
            )
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }

    private var subtitle: String {
        switch customWorkflow.mode {
        case .voice: return "Eigener Prompt – Sprache"
        case .selection: return "Eigener Prompt – Auswahl"
        }
    }
}
