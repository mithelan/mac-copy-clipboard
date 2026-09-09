import Foundation

struct HistoryItem: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case text
        case image
    }

    let id: UUID
    let date: Date
    let kind: Kind
    var text: String?
    var imageFileName: String?

    init(kind: Kind, text: String? = nil, imageFileName: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.kind = kind
        self.text = text
        self.imageFileName = imageFileName
    }
}
