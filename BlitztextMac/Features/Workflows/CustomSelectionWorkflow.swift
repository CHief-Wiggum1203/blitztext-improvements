import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class CustomSelectionWorkflow: Workflow {
    let type = WorkflowType.custom
    var phase: WorkflowPhase = .idle {
        didSet { onPhaseChange?(phase) }
    }
    var onOutput: WorkflowOutputHandler?
    var onPhaseChange: WorkflowPhaseChangeHandler?

    let customWorkflow: CustomWorkflow
    private let llmProvider: any LLMProvider
    private var processingTask: Task<Void, Never>?

    init(customWorkflow: CustomWorkflow, llmProvider: any LLMProvider) {
        self.customWorkflow = customWorkflow
        self.llmProvider = llmProvider
    }

    var isRecording: Bool { false }

    /// Selection workflows perform their work on `start()` so they fire immediately whether
    /// invoked from the menu or from a hold-mode hotkey (in hold-mode the API call usually
    /// completes after key release, so `stop()` becomes a no-op cancel).
    func start() {
        processingTask?.cancel()
        phase = .running("Auswahl wird gelesen ...")
        processingTask = Task {
            do {
                let selection = try await SelectionService.readSelection()
                if Task.isCancelled { return }

                phase = .running("Wird verarbeitet ...")
                let result = try await llmProvider.applyCustom(
                    text: selection,
                    prompt: customWorkflow.systemPrompt,
                    modelPreference: customWorkflow.modelPreference
                )
                if Task.isCancelled { return }

                phase = .done(result)
                onOutput?(result)
            } catch is CancellationError {
                phase = .idle
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    /// For Selection workflows the actual work happens on `start()`. If a task is still
    /// in flight (e.g. hold-mode released early), cancel it.
    func stop() {
        processingTask?.cancel()
    }

    func reset() {
        processingTask?.cancel()
        phase = .idle
    }
}
