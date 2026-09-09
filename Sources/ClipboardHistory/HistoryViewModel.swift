import AppKit
import Combine

final class HistoryViewModel: ObservableObject {
    @Published var items: [HistoryItem] = []
    @Published var searchText: String = "" {
        didSet { applyFilter() }
    }
    @Published var selectedIndex: Int = 0

    private(set) var allItems: [HistoryItem] = []

    func refresh() {
        allItems = HistoryStore.shared.items
        applyFilter()
    }

    private func applyFilter() {
        if searchText.isEmpty {
            items = allItems
        } else {
            let query = searchText.lowercased()
            items = allItems.filter { item in
                switch item.kind {
                case .text:
                    return item.text?.lowercased().contains(query) ?? false
                case .image:
                    return "screenshot image".contains(query)
                }
            }
        }
        if selectedIndex >= items.count {
            selectedIndex = max(0, items.count - 1)
        }
    }

    func image(for item: HistoryItem) -> NSImage? {
        HistoryStore.shared.image(for: item)
    }

    func moveSelection(by delta: Int) {
        guard !items.isEmpty else { return }
        selectedIndex = min(max(0, selectedIndex + delta), items.count - 1)
    }

    @discardableResult
    func confirmSelection() -> HistoryItem? {
        guard items.indices.contains(selectedIndex) else { return nil }
        let item = items[selectedIndex]
        copyToPasteboard(item)
        return item
    }

    func remove(_ item: HistoryItem) {
        HistoryStore.shared.remove(item)
        refresh()
    }

    func removeSelected() {
        guard items.indices.contains(selectedIndex) else { return }
        remove(items[selectedIndex])
    }

    func clearAll() {
        HistoryStore.shared.clear()
        refresh()
    }

    private func copyToPasteboard(_ item: HistoryItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch item.kind {
        case .text:
            if let text = item.text {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let image = HistoryStore.shared.image(for: item) {
                pasteboard.writeObjects([image])
            }
        }
    }
}
