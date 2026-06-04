import SwiftUI

/// Active-state detail view for both voice and selection custom workflows.
///
/// Mirrors the styling of `TranscriptionActiveView` / `TextImproverActiveView` so the
/// menu-bar popover feels consistent across all workflow types.
struct CustomWorkflowActiveView: View {
    enum Mode {
        case voice
        case selection
    }

    let mode: Mode
    let isRecording: Bool
    let audioLevel: Float
    let phase: WorkflowPhase
    let onStop: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle:
            if mode == .voice && isRecording {
                recordingView
            } else {
                processingView(message: defaultIdleMessage)
            }

        case .running(let msg):
            if mode == .voice && isRecording {
                recordingView
            } else {
                processingView(message: msg)
            }

        case .done(let text):
            autoPasteView(text: text)

        case .error(let msg):
            errorView(message: msg)
        }
    }

    private var defaultIdleMessage: String {
        switch mode {
        case .voice: return "Bereit \u{2026}"
        case .selection: return "Auswahl wird verarbeitet \u{2026}"
        }
    }

    // MARK: - Recording (voice mode)

    private var recordingView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 20)

            WaveformView(audioLevel: audioLevel, isRecording: true)
                .frame(height: 44)
                .padding(.horizontal, 24)

            Button(action: onStop) {
                ZStack {
                    Circle()
                        .strokeBorder(.primary.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 44, height: 44)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.primary.opacity(0.7))
                        .frame(width: 14, height: 14)
                }
            }
            .buttonStyle(.plain)

            Text("Ich h\u{00F6}re zu \u{2026} Klicke zum Stoppen.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)

            Spacer().frame(height: 8)
        }
    }

    // MARK: - Processing

    private func processingView(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 24)
            ProgressView()
                .scaleEffect(0.7)
                .controlSize(.small)
            Text(message)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 24)
        }
    }

    // MARK: - Result

    private func autoPasteView(text: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 20)

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.green)
            }

            Text("Eingef\u{00FC}gt")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Spacer().frame(height: 12)
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Spacer().frame(height: 16)

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.orange)
            }

            Text(message)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)

            Button(action: onCancel) {
                Text("Schlie\u{00DF}en")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            }
            .buttonStyle(SubtleButtonStyle())

            Spacer().frame(height: 4)
        }
    }
}
