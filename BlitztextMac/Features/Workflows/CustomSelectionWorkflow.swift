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

    func start() {
        // Selection mode does its work on `stop()` so the press-and-release semantics
        // match the other workflows. On `start()` we just signal "waiting" briefly.
        phase = .running("Auswahl wird gelesen ...")
    }

    func stop() {
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
                phase = .done(result)
                onOutput?(result)
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    func reset() {
        processingTask?.cancel()
        phase = .idle
    }
}
