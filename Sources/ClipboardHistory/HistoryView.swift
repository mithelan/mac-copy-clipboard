import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    var onConfirm: () -> Void
    var onDismiss: () -> Void
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard history", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
            }
            .padding(10)

            Divider()

            if viewModel.items.isEmpty {
                Spacer()
                Text("No clipboard history yet")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    List(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        HistoryRow(item: item, isSelected: index == viewModel.selectedIndex, viewModel: viewModel)
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedIndex = index
                                onConfirm()
                            }
                    }
                    .listStyle(.plain)
                    .onChange(of: viewModel.selectedIndex) {
                        proxy.scrollTo(viewModel.selectedIndex, anchor: .center)
                    }
                }
            }

            Divider()
            HStack {
                Text("\u{2191}\u{2193} navigate \u{00B7} \u{21B5} paste \u{00B7} esc close")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
        }
        .frame(width: 420, height: 480)
        .onAppear {
            DispatchQueue.main.async { searchFocused = true }
        }
    }
}

struct HistoryRow: View {
    let item: HistoryItem
    let isSelected: Bool
    @ObservedObject var viewModel: HistoryViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            switch item.kind {
            case .text:
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.text ?? "")
                        .lineLimit(3)
                        .font(.system(size: 13))
                    Text(formattedTimestamp(item.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            case .image:
                if let image = viewModel.image(for: item) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "photo")
                        .frame(width: 40, height: 40)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Screenshot")
                        .font(.system(size: 13))
                    Text(formattedTimestamp(item.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
    }
}

private func formattedTimestamp(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
        return date.formatted(date: .omitted, time: .shortened)
    }
    return date.formatted(date: .abbreviated, time: .shortened)
}
