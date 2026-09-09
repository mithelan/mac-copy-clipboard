import AppKit

/// Watches the macOS screenshot save location (Desktop by default, or the
/// folder configured via `defaults write com.apple.screencapture location`)
/// and feeds newly-created screenshot files into the clipboard history.
final class ScreenshotWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var directoryFD: CInt = -1
    private var knownFiles: Set<String> = []
    private let watchURL: URL

    init() {
        watchURL = ScreenshotWatcher.resolveScreenshotDirectory()
    }

    func start() {
        knownFiles = Set(currentScreenshotFiles())

        directoryFD = open(watchURL.path, O_EVTONLY)
        guard directoryFD >= 0 else { return }

        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: directoryFD,
            eventMask: [.write],
            queue: DispatchQueue.main
        )
        newSource.setEventHandler { [weak self] in
            self?.handleDirectoryChange()
        }
        let fd = directoryFD
        newSource.setCancelHandler {
            close(fd)
        }
        newSource.resume()
        source = newSource
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    private static func resolveScreenshotDirectory() -> URL {
        if let location = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            let expanded = (location as NSString).expandingTildeInPath
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir), isDir.boolValue {
                return URL(fileURLWithPath: expanded)
            }
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    }

    private func currentScreenshotFiles() -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: watchURL.path)) ?? []
        return names.filter { ScreenshotWatcher.isScreenshotName($0) }
    }

    private static func isScreenshotName(_ name: String) -> Bool {
        let lower = name.lowercased()
        let hasImageExtension = lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg")
        let looksLikeScreenshot = lower.hasPrefix("screenshot") || lower.hasPrefix("screen shot")
        return hasImageExtension && looksLikeScreenshot
    }

    private func handleDirectoryChange() {
        let files = Set(currentScreenshotFiles())
        let newFiles = files.subtracting(knownFiles)
        knownFiles = files

        for name in newFiles {
            let url = watchURL.appendingPathComponent(name)
            // Give the screenshot process a moment to finish writing the file.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                guard let image = NSImage(contentsOf: url) else { return }
                HistoryStore.shared.addImage(image)
            }
        }
    }
}
