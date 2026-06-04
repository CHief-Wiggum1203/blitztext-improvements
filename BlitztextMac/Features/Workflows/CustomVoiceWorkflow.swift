import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class CustomVoiceWorkflow: Workflow {
    let type = WorkflowType.custom
    var phase: WorkflowPhase = .idle {
        didSet { onPhaseChange?(phase) }
    }
    var onOutput: WorkflowOutputHandler?
    var onPhaseChange: WorkflowPhaseChangeHandler?

    /// The configured custom workflow this instance executes.
    let customWorkflow: CustomWorkflow

    private let recorder = AudioRecorder()
    private let language: String
    private let onlineModel: OnlineTranscriptionModel
    private let llmProvider: any LLMProvider
    private var processingTask: Task<Void, Never>?

    init(customWorkflow: CustomWorkflow,
         language: String = "de",
         onlineModel: OnlineTranscriptionModel = .gpt4oTranscribe,
         llmProvider: any LLMProvider) {
        self.customWorkflow = customWorkflow
        self.language = language
        self.onlineModel = onlineModel
        self.llmProvider = llmProvider
    }

    var isRecording: Bool { recorder.isRecording }
    var audioLevel: Float { recorder.audioLevel }

    func start() {
        phase = .running("Aufnahme l\u{00E4}uft ...")
        recorder.startRecording()
        if let error = recorder.errorMessage {
            phase = .error(error)
        }
    }

    func stop() {
        if recorder.isRecording {
            recorder.stopRecording()
            guard !TranscriptionQualityService.shouldRejectRecording(duration: recorder.lastRecordingDuration) else {
                recorder.discardRecording()
                phase = .error("Keine Aufnahme erkannt.")
                return
            }
            processRecording()
        } else {
            processingTask?.cancel()
            phase = .idle
        }
    }

    func reset() {
        processingTask?.cancel()
        if recorder.isRecording { recorder.stopRecording() }
        recorder.discardRecording()
        phase = .idle
    }

    private func processRecording() {
        guard let url = recorder.recordingURL else {
            phase = .error("Keine Aufnahme vorhanden.")
            return
        }
        phase = .running("Wird transkribiert ...")
        let recordingDuration = recorder.lastRecordingDuration

        processingTask = Task {
            defer { try? FileManager.default.removeItem(at: url) }
            do {
                let rawText = try await TranscriptionService.transcribe(
                    audioURL: url,
                    customTerms: [],
                    language: language,
                    model: onlineModel
                )
                let cleanedRawText = TranscriptionQualityService.cleanedTranscript(rawText)
                guard !TranscriptionQualityService.isLikelyArtifact(cleanedRawText, recordingDuration: recordingDuration) else {
                    phase = .error("Keine Aufnahme erkannt.")
                    return
                }
                if Task.isCancelled { return }

                phase = .running("Wird verarbeitet ...")
                let result = try await llmProvider.applyCustom(
                    text: cleanedRawText,
                    prompt: customWorkflow.systemPrompt,
                    modelPreference: customWorkflow.modelPreference
                )
                let cleaned = TranscriptionQualityService.cleanedTranscript(result)
                phase = .done(cleaned)
                onOutput?(cleaned)
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }
}
