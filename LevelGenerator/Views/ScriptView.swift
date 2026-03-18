import SwiftUI

struct ScriptView: View {
    @Binding var script: SavedScript
    @Environment(\.dismiss) var dismiss

    @State private var selectedImage: String = "player"
    @State private var currentDialog: String = ""
    @State private var currentName: String
    @State private var dialogs: [(image: String, text: String, key: String)]

    let availableImages = [
        "player", "playerWorry", "playerSurprise",
        "radioHand", "radioPocket", "radioRing",
        "notesHand", "playerHappy", "playerAngry", "playerSleepy", "playerCry"
    ]

    // Propiedades públicas para SavedScript.update(with:)
    var scriptName: String { currentName }
    var scriptDialogs: [(image: String, text: String, key: String)] { dialogs }

    init(script: Binding<SavedScript>) {
        self._script = script
        _currentName = State(initialValue: script.wrappedValue.name)
        _dialogs = State(initialValue: script.wrappedValue.dialogs.map { dialog in
            (image: dialog.image, text: dialog.text, key: dialog.key)
        })
    }

    // MARK: - Computed: key generation

    private func generateScriptKey() -> String {
        let formattedName = currentName.lowercased().replacingOccurrences(of: " ", with: "-")
        let dialogCount = dialogs.filter { $0.key.starts(with: formattedName) }.count + 1
        let numberString = String(format: "%02d", dialogCount)
        return "\(formattedName)-\(numberString)"
    }

    // MARK: - Computed: outputs via ScriptLuaGenerator

    var generatedLuaScript: String {
        let tempScript = SavedScript(
            name: currentName,
            dialogs: dialogs.map { SavedScript.SavedDialog(image: $0.image, text: $0.text, key: $0.key) }
        )
        return ScriptLuaGenerator.lua(for: tempScript)
    }

    var generatedLocalization: String {
        let tempScript = SavedScript(
            name: currentName,
            dialogs: dialogs.map { SavedScript.SavedDialog(image: $0.image, text: $0.text, key: $0.key) }
        )
        return ScriptLuaGenerator.localization(for: tempScript)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {

            // ── Left Column: outputs ──────────────────────────────────────
            ScrollView {
                VStack(spacing: 12) {

                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Generated Lua Script")
                                    .font(.headline)
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
                                Text("Generated Localization")
                                    .font(.headline)
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

            // ── Center Column: diálogos ───────────────────────────────────
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(dialogs.enumerated()), id: \.offset) { index, dialog in
                            DialogRow(
                                image: dialog.image,
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

            // ── Right Column: input de diálogo ────────────────────────────
            VStack(spacing: 16) {

                GroupBox("Select Character") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.fixed(110))], spacing: 8) {
                            ForEach(availableImages, id: \.self) { image in
                                Button {
                                    selectedImage = image
                                } label: {
                                    Image(image)
                                        .resizable()
                                        .frame(width: 118, height: 94)
                                        .padding(8)
                                        .background(selectedImage == image ? Color.blue.opacity(0.2) : Color.clear)
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
                        set: { newValue in
                            if newValue.count <= 94 { currentDialog = newValue }
                        }
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

                Button {
                    if !currentDialog.isEmpty && !currentName.isEmpty {
                        dialogs.append((
                            image: selectedImage,
                            text: currentDialog,
                            key: generateScriptKey()
                        ))
                        currentDialog = ""
                    }
                } label: {
                    Text("Add Dialog")
                        .frame(maxWidth: .infinity)
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
                    var updatedScript = script
                    updatedScript.update(with: self)
                    script = updatedScript
                    dismiss()
                }
            }
        }
    }
}
