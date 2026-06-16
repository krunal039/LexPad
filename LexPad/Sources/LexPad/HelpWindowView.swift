import LexPadCore
import SwiftUI

struct HelpDocumentView: View {
    let topic: HelpTopic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    private var markdown: String { HelpSupport.loadMarkdown(for: topic) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(topic.title)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText)
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.toolbarBackground)
            .overlay(alignment: .bottom) {
                theme.separator.frame(height: 1)
            }

            ScrollView {
                Group {
                    if let attributed = try? AttributedString(
                        markdown: markdown,
                        options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
                    ) {
                        Text(attributed)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(markdown)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
        }
        .lexPadSheetContainer()
        .frame(minWidth: 680, minHeight: 520)
    }
}

struct AboutLexPadView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let icon = HelpSupport.appIconImage() {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 96, height: 96)
                        .padding(.top, 8)
                }

                VStack(spacing: 6) {
                    Text("LexPad")
                        .font(.system(size: 28, weight: .semibold))
                    Text(HelpSupport.versionLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Native macOS text editor inspired by Notepad++.\nFast editing, regex search, 160+ languages, and Scintilla-powered syntax highlighting.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 400)

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("Developer") {
                            Text(HelpSupport.developerName)
                                .multilineTextAlignment(.trailing)
                        }
                        LabeledContent("Website") {
                            Link(HelpSupport.repositoryDisplayPath, destination: HelpSupport.repositoryURL)
                        }
                        LabeledContent("Copyright") {
                            Text("© \(HelpSupport.copyrightYear) \(HelpSupport.developerName)")
                                .multilineTextAlignment(.trailing)
                        }
                        LabeledContent("License") {
                            Text("Open source — see Licenses")
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: 400)

                HStack(spacing: 12) {
                    Button("Open Source Licenses") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            HelpSupport.showHelp(.licenses)
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("View on GitHub") {
                        HelpSupport.openRepository()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Close") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .lexPadSheetContainer()
        .frame(width: 460, height: 520)
    }
}

struct HelpNotificationsModifier: ViewModifier {
    @ObservedObject var settings: EditorSettings
    @State private var helpTopic: HelpTopic?
    @State private var showAbout = false

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadShowHelp)) { note in
                if let raw = note.userInfo?["topic"] as? String,
                   let topic = HelpTopic(rawValue: raw) {
                    helpTopic = topic
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadShowAbout)) { _ in
                showAbout = true
            }
            .sheet(item: $helpTopic) { topic in
                HelpDocumentView(topic: topic)
                    .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showAbout) {
                AboutLexPadView()
                    .lexPadTheme(settings: settings)
            }
    }
}

extension View {
    func helpNotifications(settings: EditorSettings) -> some View {
        modifier(HelpNotificationsModifier(settings: settings))
    }
}
