import AppKit
import SwiftUI

final class HistoryPanelController: NSObject, NSWindowDelegate {
    static let shared = HistoryPanelController()

    private var panel: NSPanel?
    private let viewModel = HistoryViewModel()
    private var keyMonitor: Any?
    private var previousApp: NSRunningApplication?

    func toggle() {
        if let panel = panel, panel.isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        viewModel.refresh()
        viewModel.searchText = ""
        viewModel.selectedIndex = 0

        if panel == nil {
            let hosting = NSHostingView(rootView: HistoryView(
                viewModel: viewModel,
                onConfirm: { [weak self] in
                    self?.confirmAndDismiss()
                },
                onDismiss: { [weak self] in
                    self?.close()
                }
            ))
            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
                styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            newPanel.titleVisibility = .hidden
            newPanel.titlebarAppearsTransparent = true
            newPanel.isFloatingPanel = true
            newPanel.level = .floating
            newPanel.hidesOnDeactivate = false
            newPanel.isReleasedWhenClosed = false
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.contentView = hosting
            newPanel.delegate = self
            panel = newPanel
        }

        guard let panel = panel else { return }
        centerNearMouse(panel)
        installKeyMonitor()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
        removeKeyMonitor()
        previousApp?.activate(options: [])
        previousApp = nil
    }

    /// Copies the selected item and pastes it into whichever app was
    /// frontmost before the panel opened.
    private func confirmAndDismiss() {
        viewModel.confirmSelection()

        panel?.orderOut(nil)
        removeKeyMonitor()
        let appToRestore = previousApp
        previousApp = nil
        appToRestore?.activate(options: [])

        guard PasteSimulator.isTrusted(promptIfNeeded: true) else {
            // Not granted yet — macOS just showed (or already showed) the
            // Accessibility prompt. The item is still on the clipboard, so
            // the user can paste manually with Cmd+V this time.
            return
        }

        // Give the target app a moment to actually become frontmost before
        // the synthetic keystroke is delivered.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            PasteSimulator.sendCommandV()
        }
    }

    func windowWillClose(_ notification: Notification) {
        removeKeyMonitor()
    }

    private func centerNearMouse(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
        guard let screen = screen else { return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            switch event.keyCode {
            case 125: // down arrow
                self.viewModel.moveSelection(by: 1)
                return nil
            case 126: // up arrow
                self.viewModel.moveSelection(by: -1)
                return nil
            case 36, 76: // return / keypad enter
                self.confirmAndDismiss()
                return nil
            case 53: // escape
                self.close()
                return nil
            case 51, 117: // delete / forward delete
                self.viewModel.removeSelected()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor = keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        keyMonitor = nil
    }
}
