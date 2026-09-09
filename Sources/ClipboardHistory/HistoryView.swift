import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    var onConfirm: () -> Void
    var onDismiss: () -> Void
    @FocusState private var searchFocused: Bool
    @State private var hoveredIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard history", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)

                Button {
                    viewModel.clearAll()
                } label: {
                    Text("Clear")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(viewModel.allItems.isEmpty ? 0 : 1)
                .disabled(viewModel.allItems.isEmpty)
                .help("Clear all clipboard history")
            }
            .padding(10)

            Divider()

            if viewModel.items.isEmpty {
                Spacer()
                Text(viewModel.allItems.isEmpty ? "No clipboard history yet" : "No matches")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    List(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        HistoryRow(
                            item: item,
                            isSelected: index == viewModel.selectedIndex,
                            isHovered: hoveredIndex == index,
                            viewModel: viewModel,
                            onDelete: {
                                viewModel.remove(item)
                            }
                        )
                        .id(index)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedIndex = index
                            onConfirm()
                        }
                        .onHover { isInside in
                            hoveredIndex = isInside ? index : (hoveredIndex == index ? nil : hoveredIndex)
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
                Text("\u{2191}\u{2193} navigate \u{00B7} \u{21B5} paste \u{00B7} \u{232B} delete \u{00B7} esc close")
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
    let isHovered: Bool
    @ObservedObject var viewModel: HistoryViewModel
    var onDelete: () -> Void

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

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove this item")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            isSelected ? Color.accentColor.opacity(0.2)
                : isHovered ? Color.secondary.opacity(0.1)
                : Color.clear
        )
        .cornerRadius(6)
    }
}

private func formattedTimestamp(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
        return date.formatted(date: .omitted, time: .shortened)
    }
    return date.formatted(date: .abbreviated, time: .shortened)
}
