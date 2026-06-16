import LexPadCore
import SwiftUI

struct FindBarView: View {
    @Binding var pattern: String
    @Binding var isRegex: Bool
    @Binding var matchCase: Bool
    let matchCount: Int
    let onFindNext: () -> Void
    let onFindPrevious: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Find", text: $pattern)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 220)
                .onSubmit(onFindNext)

            Toggle("Regex", isOn: $isRegex)
                .toggleStyle(.checkbox)
            Toggle("Match case", isOn: $matchCase)
                .toggleStyle(.checkbox)

            Text(matchCount == 0 ? "No matches" : "\(matchCount) matches")
                .foregroundStyle(.secondary)
                .frame(minWidth: 90, alignment: .leading)

            Button("Previous", action: onFindPrevious)
            Button("Next", action: onFindNext)
            Button("Close", action: onClose)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct TabStripView: View {
    @ObservedObject var collection: DocumentCollection
    let onClose: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(collection.documents, id: \.id) { document in
                    tabButton(for: document)
                }
            }
        }
        .frame(height: 30)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func tabButton(for document: TextDocument) -> some View {
        let isActive = collection.activeDocumentID == document.id
        return HStack(spacing: 6) {
            Text(document.displayName)
                .lineLimit(1)
            Button {
                onClose(document.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
            .opacity(0.7)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
        .overlay(alignment: .bottom) {
            if isActive {
                Rectangle().fill(Color.accentColor).frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            collection.activeDocumentID = document.id
        }
    }
}

struct StatusBarView: View {
    let document: TextDocument?
    let matchCount: Int

    var body: some View {
        HStack(spacing: 16) {
            Text("Ln \(document?.caret.line ?? 1), Col \(document?.caret.column ?? 1)")
            Text(document?.language.rawValue ?? "Plain Text")
            Text(document?.endOfLine.displayName ?? "Unix (LF)")
            Text("UTF-8")
            Spacer()
            if matchCount > 0 {
                Text("\(matchCount) matches")
            }
            Text("\(document?.lineCount ?? 1) lines")
            Text("\(document?.characterCount ?? 0) chars")
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
