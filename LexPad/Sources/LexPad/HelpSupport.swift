import AppKit
import Foundation
import LexPadCore

enum HelpTopic: String, Identifiable, CaseIterable {
    case gettingStarted
    case userGuide
    case shortcuts
    case changelog
    case licenses

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gettingStarted: return "Getting Started"
        case .userGuide: return "User Guide"
        case .shortcuts: return "Keyboard Shortcuts"
        case .changelog: return "What's New"
        case .licenses: return "Open Source Licenses"
        }
    }

    var menuTitle: String {
        switch self {
        case .gettingStarted: return "Getting Started Guide"
        case .userGuide: return "User Guide"
        case .shortcuts: return "Keyboard Shortcuts"
        case .changelog: return "What's New in LexPad"
        case .licenses: return "Open Source Licenses"
        }
    }

    var resourceName: String {
        switch self {
        case .gettingStarted: return "GETTING_STARTED"
        case .userGuide: return "USER_GUIDE"
        case .shortcuts: return "SHORTCUTS"
        case .changelog: return "CHANGELOG"
        case .licenses: return "LICENSES"
        }
    }
}

enum HelpSupport {
    static let repositoryURL = URL(string: "https://github.com/krunal039/LexPad")!
    static let issuesURL = URL(string: "https://github.com/krunal039/LexPad/issues")!
    static let repositoryDisplayPath = "github.com/krunal039/LexPad"
    static let developerName = "Codetails LTD"
    static let copyrightYear = "2026"

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.3.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var versionLabel: String {
        "Version \(appVersion) (\(buildNumber))"
    }

    static func loadMarkdown(for topic: HelpTopic) -> String {
        if let url = resolveURL(for: topic),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return "# \(topic.title)\n\nDocumentation file not found.\n\nLook in the `docs/` folder of the LexPad repository."
    }

    static func openInBrowser(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    static func openRepository() {
        openInBrowser(repositoryURL)
    }

    static func openIssues() {
        openInBrowser(issuesURL)
    }

    static func openOnlineDocs() {
        openInBrowser(repositoryURL.appendingPathComponent("blob/main/docs/USER_GUIDE.md"))
    }

    static func showHelp(_ topic: HelpTopic) {
        NotificationCenter.default.post(
            name: .lexPadShowHelp,
            object: nil,
            userInfo: ["topic": topic.rawValue]
        )
    }

    static func showAbout() {
        NotificationCenter.default.post(name: .lexPadShowAbout, object: nil)
    }

    static func appIconImage() -> NSImage? {
        if let icon = NSApp.applicationIconImage { return icon }
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return NSImage(named: NSImage.applicationIconName)
    }

    private static func resolveURL(for topic: HelpTopic) -> URL? {
        let name = topic.resourceName
        if let bundled = Bundle.main.url(forResource: name, withExtension: "md", subdirectory: "Help") {
            return bundled
        }
        if let bundled = Bundle.main.url(forResource: name, withExtension: "md") {
            return bundled
        }

        let fm = FileManager.default
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        let candidates = [
            cwd.appendingPathComponent("../docs/\(name).md"),
            cwd.appendingPathComponent("docs/\(name).md"),
            cwd.deletingLastPathComponent().appendingPathComponent("docs/\(name).md"),
        ]
        for url in candidates {
            let normalized = url.standardizedFileURL
            if fm.fileExists(atPath: normalized.path) { return normalized }
        }
        if topic == .changelog {
            for url in [cwd.appendingPathComponent("../CHANGELOG.md"), cwd.appendingPathComponent("CHANGELOG.md")] {
                let normalized = url.standardizedFileURL
                if fm.fileExists(atPath: normalized.path) { return normalized }
            }
        }
        return nil
    }
}
