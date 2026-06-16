import Foundation
import SwiftUI

public enum TabGroupingMode: String, CaseIterable, Sendable, Identifiable, Codable {
    case flat
    case byFolder
    case byGroup

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .flat: return "Flat"
        case .byFolder: return "By Folder"
        case .byGroup: return "By Group"
        }
    }
}

public struct TabGroup: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var colorIndex: Int
    public var documentIDs: [UUID]

    public init(id: UUID = UUID(), name: String, colorIndex: Int = 0, documentIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
        self.documentIDs = documentIDs
    }

    public static let palette: [String] = ["blue", "green", "orange", "purple", "pink", "teal"]
}

public struct TabGroupSection: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let colorIndex: Int?
    public let documentIDs: [UUID]

    public init(id: String, title: String, colorIndex: Int? = nil, documentIDs: [UUID]) {
        self.id = id
        self.title = title
        self.colorIndex = colorIndex
        self.documentIDs = documentIDs
    }
}

@MainActor
public final class TabGroupStore: ObservableObject {
    @Published public var mode: TabGroupingMode = .flat
    @Published public var groups: [TabGroup] = []
    @Published public var nextGroupNumber = 1

    public init() {
        if let data = UserDefaults.standard.data(forKey: "tabGroups"),
           let decoded = try? JSONDecoder().decode([TabGroup].self, from: data) {
            groups = decoded
        }
        if let raw = UserDefaults.standard.string(forKey: "tabGroupingMode"),
           let mode = TabGroupingMode(rawValue: raw) {
            self.mode = mode
        }
        sanitizeGroups()
        nextGroupNumber = (groups.map { $0.name }.compactMap { name -> Int? in
            guard name.hasPrefix("Group ") else { return nil }
            return Int(name.dropFirst(6))
        }.max() ?? 0) + 1
    }

    /// Removes empty/orphan groups and merges duplicate names so menus stay in sync with the sidebar.
    public func sanitizeGroups() {
        var mergedByName: [String: TabGroup] = [:]
        for group in groups {
            let name = group.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            var normalized = group
            normalized.name = name
            normalized.documentIDs = Array(Set(normalized.documentIDs))
            if let existing = mergedByName[name] {
                var winner = existing.documentIDs.count >= normalized.documentIDs.count ? existing : normalized
                let loser = winner.id == existing.id ? normalized : existing
                var combined = winner
                for docID in loser.documentIDs where !combined.documentIDs.contains(docID) {
                    combined.documentIDs.append(docID)
                }
                mergedByName[name] = combined
            } else {
                mergedByName[name] = normalized
            }
        }
        groups = mergedByName.values
            .filter { !$0.documentIDs.isEmpty }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func persist() {
        sanitizeGroups()
        UserDefaults.standard.set(mode.rawValue, forKey: "tabGroupingMode")
        if let data = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(data, forKey: "tabGroups")
        }
    }

    public func groupID(for documentID: UUID) -> UUID? {
        groups.first { $0.documentIDs.contains(documentID) }?.id
    }

    public func createGroup(name: String? = nil, documentIDs: [UUID] = []) -> TabGroup {
        let title = name ?? "Group \(nextGroupNumber)"
        nextGroupNumber += 1
        let group = TabGroup(name: title, colorIndex: groups.count % TabGroup.palette.count, documentIDs: documentIDs)
        groups.append(group)
        persist()
        return groups.first { $0.id == group.id } ?? groups.first { $0.name == title } ?? group
    }

    public func addDocument(_ documentID: UUID, to groupID: UUID) {
        for i in groups.indices {
            groups[i].documentIDs.removeAll { $0 == documentID }
        }
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        if !groups[index].documentIDs.contains(documentID) {
            groups[index].documentIDs.append(documentID)
        }
        persist()
    }

    public func removeDocument(_ documentID: UUID) {
        for i in groups.indices {
            groups[i].documentIDs.removeAll { $0 == documentID }
        }
        groups.removeAll { $0.documentIDs.isEmpty }
        persist()
    }

    public func updateGroup(id: UUID, name: String? = nil, colorIndex: Int? = nil) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        if let name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            groups[index].name = name
        }
        if let colorIndex {
            groups[index].colorIndex = colorIndex % TabGroup.palette.count
        }
        persist()
    }

    public func deleteGroup(id: UUID) {
        groups.removeAll { $0.id == id }
        persist()
    }

    public func group(for documentID: UUID) -> TabGroup? {
        guard let id = groupID(for: documentID) else { return nil }
        return groups.first { $0.id == id }
    }

    public func sections(for documents: [TextDocument]) -> [TabGroupSection] {
        switch mode {
        case .flat:
            return [TabGroupSection(id: "all", title: "Open Tabs", documentIDs: documents.map(\.id))]
        case .byFolder:
            var buckets: [String: [UUID]] = [:]
            for doc in documents {
                let key: String
                if let url = doc.url?.deletingLastPathComponent().path {
                    key = url.isEmpty ? "Untitled" : url
                } else {
                    key = "Untitled"
                }
                buckets[key, default: []].append(doc.id)
            }
            return buckets.keys.sorted().map { key in
                TabGroupSection(id: key, title: (key as NSString).lastPathComponent, documentIDs: buckets[key] ?? [])
            }
        case .byGroup:
            var assigned = Set<UUID>()
            var result: [TabGroupSection] = []
            for group in groups {
                let ids = group.documentIDs.filter { id in documents.contains { $0.id == id } }
                assigned.formUnion(ids)
                if !ids.isEmpty {
                    result.append(TabGroupSection(id: group.id.uuidString, title: group.name, colorIndex: group.colorIndex, documentIDs: ids))
                }
            }
            let ungrouped = documents.map(\.id).filter { !assigned.contains($0) }
            if !ungrouped.isEmpty {
                result.append(TabGroupSection(id: "ungrouped", title: "Ungrouped", documentIDs: ungrouped))
            }
            return result
        }
    }
}
