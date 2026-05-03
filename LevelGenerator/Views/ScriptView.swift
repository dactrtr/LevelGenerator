import SwiftUI

struct ScriptView: View {
    @Binding var script: SavedScript
    @Environment(\.dismiss) var dismiss

    @State private var selectedVideo: String = "player"
    @State private var currentDialog: String = ""
    @State private var currentScreen: String = ""
    @State private var currentName: String
    @State private var dialogs: [(video: String, text: String, key: String, screen: String?)]

    let availableVideos = [
        "player", "playerWorry", "playerSurprise", "playerHappy",
        "playerAngry", "playerSleepy", "playerScared", "playerCry",
        "radioHand", "radioPocket", "radioRing", "notesHand"
    ]

    init(script: Binding<SavedScript>) {
        self._script = script
        _currentName = State(initialValue: script.wrappedValue.name)
        _dialogs = State(initialValue: script.wrappedValue.dialogs.map {
            (video: $0.video, text: $0.text, key: $0.key, screen: $0.screen)
        })
    }

    private func generateScriptKey() -> String {
        let formattedName = currentName.lowercased().replacingOccurrences(of: " ", with: "-")
        let count = dialogs.filter { $0.key.starts(with: formattedName) }.count + 1
        return "\(formattedName)-\(String(format: "%02d", count))"
    }

    var generatedLuaScript: String {
        ScriptLuaGenerator.lua(for: currentSavedScript)
    }

    var generatedLocalization: String {
        ScriptLuaGenerator.localization(for: currentSavedScript)
    }

    private var currentSavedScript: SavedScript {
        SavedScript(
            name: currentName,
            dialogs: dialogs.map {
                SavedScript.SavedDialog(video: $0.video, text: $0.text, key: $0.key, screen: $0.screen.flatMap { $0.isEmpty ? nil : $0 })
            }
        )
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── Left Column: outputs ──────────────────────────────────────
            ScrollView {
                VStack(spacing: 12) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Generated Lua Script").font(.headline)
                                Spacer()
                                CopyButton(content: generatedLuaScript)
                            }
                            TextEditor(text: .constant(generatedLuaScript))
                                .font(.system(size: 9, design: .monospaced))
                                .frame(minHeight: 140)
                        }
                    }
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Generated Localization").font(.headline)
                                Spacer()
                                CopyButton(content: generatedLocalization)
                            }
                            TextEditor(text: .constant(generatedLocalization))
                                .font(.system(size: 9, design: .monospaced))
                                .frame(minHeight: 100)
                        }
                    }
                }
                .padding()
            }
            .frame(width: 400)

            // ── Center Column: dialogs ────────────────────────────────────
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(dialogs.enumerated()), id: \.offset) { index, dialog in
                            DialogRow(
                                video: dialog.video,
                                text: dialog.text,
                                onDelete: { dialogs.remove(at: index) }
                            )
                        }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .background(PlatformColor.background)

            // ── Right Column: input ───────────────────────────────────────
            VStack(spacing: 16) {
                GroupBox("Select Character") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.fixed(110))], spacing: 8) {
                            ForEach(availableVideos, id: \.self) { video in
                                Button { selectedVideo = video } label: {
                                    Image(video)
                                        .resizable()
                                        .frame(width: 118, height: 94)
                                        .padding(8)
                                        .background(selectedVideo == video ? Color.blue.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                GroupBox("Dialog Name") {
                    TextField("Enter dialog name", text: $currentName)
                        .textFieldStyle(.roundedBorder)
                }

                GroupBox("Dialog Text") {
                    TextEditor(text: Binding(
                        get: { currentDialog },
                        set: { if $0.count <= 94 { currentDialog = $0 } }
                    ))
                    .frame(height: 100)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(currentDialog.count)/94")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(4)
                            }
                        }
                    )
                }

                GroupBox("Screen (opcional)") {
                    TextField("Nombre de imagen", text: $currentScreen)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    guard !currentDialog.isEmpty && !currentName.isEmpty else { return }
                    dialogs.append((
                        video: selectedVideo,
                        text: currentDialog,
                        key: generateScriptKey(),
                        screen: currentScreen.isEmpty ? nil : currentScreen
                    ))
                    currentDialog = ""
                    currentScreen = ""
                } label: {
                    Text("Add Dialog").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentDialog.isEmpty || currentName.isEmpty)

                Spacer()
            }
            .frame(width: 300)
            .padding()
            .background(PlatformColor.groupedBackground)
        }
        .navigationTitle(script.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    script = currentSavedScript
                    dismiss()
                }
            }
        }
    }
}
