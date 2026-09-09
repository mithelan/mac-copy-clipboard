import AppKit

final class HistoryStore {
    static let shared = HistoryStore()

    private let maxItems = 10
    private(set) var items: [HistoryItem] = []

    private let supportDir: URL
    private let imagesDir: URL
    private let indexFile: URL

    var onChange: (() -> Void)?

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        supportDir = base.appendingPathComponent("ClipboardHistory", isDirectory: true)
        imagesDir = supportDir.appendingPathComponent("images", isDirectory: true)
        indexFile = supportDir.appendingPathComponent("history.json")

        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        load()
    }

    func addText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let last = items.first, last.kind == .text, last.text == text { return }
        insert(HistoryItem(kind: .text, text: text))
    }

    func addImage(_ image: NSImage) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }

        if let last = items.first, last.kind == .image, let lastName = last.imageFileName,
           let existing = try? Data(contentsOf: imagesDir.appendingPathComponent(lastName)),
           existing == png {
            return
        }

        let fileName = "\(UUID().uuidString).png"
        let url = imagesDir.appendingPathComponent(fileName)
        do {
            try png.write(to: url)
        } catch {
            return
        }
        insert(HistoryItem(kind: .image, imageFileName: fileName))
    }

    func image(for item: HistoryItem) -> NSImage? {
        guard let name = item.imageFileName else { return nil }
        return NSImage(contentsOf: imagesDir.appendingPathComponent(name))
    }

    func clear() {
        items.removeAll()
        try? FileManager.default.removeItem(at: imagesDir)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        save()
        onChange?()
    }

    private func insert(_ item: HistoryItem) {
        items.insert(item, at: 0)
        if items.count > maxItems {
            let removed = items.removeLast()
            if let name = removed.imageFileName {
                try? FileManager.default.removeItem(at: imagesDir.appendingPathComponent(name))
            }
        }
        save()
        onChange?()
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexFile),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: indexFile)
    }
}
