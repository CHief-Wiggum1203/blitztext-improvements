import SwiftUI

@main
struct BlitztextMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let menuBarStatusController = MenuBarStatusController()
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            menuBarStatusController.attach(to: button)
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 480)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: MenuBarView(appState: appState))

        NSApp.setActivationPolicy(.accessory)

        // Hotkey events
        appState.hotkeyService.onHotkeyEvent = { [weak self] event in
            self?.handleHotkeyEvent(event)
        }
        appState.onMenuBarStatusChange = { [weak self] status in
            self?.menuBarStatusController.update(to: status)
        }
        appState.hotkeyService.start()

        // Listen for popover dismiss requests (from auto-paste)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDismissPopover),
            name: .dismissPopover,
            object: nil
        )

        DispatchQueue.main.async { [weak self] in
            self?.showOnboardingIfNeeded()
        }
    }

    @objc private func handleDismissPopover() {
        appState.isPopoverShown = false
        popover.performClose(nil)
    }

    private func handleHotkeyEvent(_ event: HotkeyEvent) {
        switch event {
        case .down(let id):
            handleHotkeyDown(id)
        case .up(let id):
            handleHotkeyUp(id)
        case .cancel:
            handleHotkeyCancel()
        }
    }

    private func handleHotkeyDown(_ id: String) {
        if let type = WorkflowType(rawValue: id) {
            handleBuiltInHotkeyDown(type)
        } else if let uuid = CustomWorkflow.parseHotkeyBindingKey(id),
                  let customWorkflow = appState.appSettings.customWorkflows.first(where: { $0.id == uuid }) {
            handleCustomHotkeyDown(customWorkflow)
        }
        // Unknown id: ignore.
    }

    private func handleCustomHotkeyDown(_ customWorkflow: CustomWorkflow) {
        guard appState.isConfigured else { return }

        let mode = appState.appSettings.hotkeyMode

        switch mode {
        case .hold:
            // Hold mode: start workflow on key down
            appState.startCustomWorkflow(customWorkflow, source: .hotkeyBackground)

        case .toggle:
            // Toggle mode: if the same custom workflow is already active, stop it.
            if let active = appState.activeWorkflow,
               active.phase.isActive,
               isActiveCustomWorkflow(active, matching: customWorkflow) {
                active.stop()
            } else {
                appState.prepareForPopoverPresentation()
                appState.startCustomWorkflow(customWorkflow, source: .manual)
                showPopover()
            }
        }
    }

    private func isActiveCustomWorkflow(_ active: any Workflow, matching customWorkflow: CustomWorkflow) -> Bool {
        if let voice = active as? CustomVoiceWorkflow {
            return voice.customWorkflow.id == customWorkflow.id
        }
        if let selection = active as? CustomSelectionWorkflow {
            return selection.customWorkflow.id == customWorkflow.id
        }
        return false
    }

    private func handleBuiltInHotkeyDown(_ type: WorkflowType) {
        guard appState.isConfigured else { return }

        let mode = appState.appSettings.hotkeyMode

        switch mode {
        case .hold:
            // Hold mode: start recording on key down
            appState.startWorkflow(type, source: .hotkeyBackground)

        case .toggle:
            // Toggle mode: if already recording same workflow, stop it
            if let active = appState.activeWorkflow,
               active.type == type,
               active.phase.isActive {
                active.stop()
            } else {
                appState.prepareForPopoverPresentation()
                appState.startWorkflow(type, source: .manual)
                showPopover()
            }
        }
    }

    private func handleHotkeyUp(_ id: String) {
        if let type = WorkflowType(rawValue: id) {
            handleBuiltInHotkeyUp(type)
        } else if let uuid = CustomWorkflow.parseHotkeyBindingKey(id),
                  let customWorkflow = appState.appSettings.customWorkflows.first(where: { $0.id == uuid }) {
            handleCustomHotkeyUp(customWorkflow)
        }
        // Unknown id: ignore.
    }

    private func handleCustomHotkeyUp(_ customWorkflow: CustomWorkflow) {
        let mode = appState.appSettings.hotkeyMode

        guard mode == .hold else { return }

        // Hold mode: stop workflow on key release if it matches the active custom workflow.
        if let active = appState.activeWorkflow,
           isActiveCustomWorkflow(active, matching: customWorkflow),
           case .running = active.phase {
            active.stop()
        }
    }

    private func handleBuiltInHotkeyUp(_ type: WorkflowType) {
        let mode = appState.appSettings.hotkeyMode

        guard mode == .hold else { return }

        // Hold mode: stop recording on key release
        if let active = appState.activeWorkflow,
           active.type == type {
            // Only stop if currently recording (running phase)
            if case .running = active.phase {
                active.stop()
            }
        }
    }

    private func handleHotkeyCancel() {
        // Escape semantically cancels the active workflow — use reset() so that
        // pending recordings/processing are discarded rather than committed.
        // Custom workflows also respond correctly to reset() (no LLM call is fired).
        appState.activeWorkflow?.reset()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            appState.isPopoverShown = false
        } else {
            appState.prepareForPopoverPresentation()
            showPopover()
        }
    }

    private func showOnboardingIfNeeded() {
        guard appState.shouldShowOnboarding else { return }
        appState.prepareForPopoverPresentation()
        showPopover()
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        appState.isPopoverShown = true
        NSApp.activate(ignoringOtherApps: true)
    }

    nonisolated func popoverDidClose(_ notification: Notification) {
        Task { @MainActor in
            appState.isPopoverShown = false
            switch appState.currentPhase {
            case .done, .error:
                appState.resetCurrentWorkflow()
            default:
                appState.page = .main
            }
        }
    }
}
