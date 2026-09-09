import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let clipboardMonitor = ClipboardMonitor()
    private let screenshotWatcher = ScreenshotWatcher()
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        clipboardMonitor.start()
        screenshotWatcher.start()

        hotKeyManager = HotKeyManager {
            DispatchQueue.main.async {
                HistoryPanelController.shared.toggle()
            }
        }
        hotKeyManager?.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.unregister()
        clipboardMonitor.stop()
        screenshotWatcher.stop()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")

        let menu = NSMenu()
        let showItem = NSMenuItem(title: "Show History (\u{2318}\u{21E7}V)", action: #selector(showHistory), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(NSMenuItem.separator())

        let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    @objc private func showHistory() {
        HistoryPanelController.shared.show()
    }

    @objc private func clearHistory() {
        HistoryStore.shared.clear()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
