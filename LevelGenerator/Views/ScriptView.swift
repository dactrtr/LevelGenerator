import SwiftUI

struct ScriptView: View {
    @Binding var script: SavedScript
    @Environment(\.dismiss) var dismiss

    // Parámetro opcional: nombres de scripts existentes para validar condiciones
    var availableScriptNames: [String] = []

    @State private var selectedImage: String = "player"
    @State private var currentDialog: String = ""
    @State private var currentName: String
    @State private var dialogs: [(image: String, text: String, key: String)]
    @State private var conditionalScripts: [ConditionalScript]
    @State private var showConditionals = false

    let availableImages = [
        "player", "playerWorry", "playerSurprise",
        "radioHand", "radioPocket", "radioRing",
        "notesHand", "playerHappy", "playerAngry", "playerSleepy", "playerCry"
    ]

    // Propiedades públicas para SavedScript.update(with:)
    var scriptName: String { currentName }
    var scriptDialogs: [(image: String, text: String, key: String)] { dialogs }
    var scriptConditionalScripts: [ConditionalScript] { conditionalScripts }

    init(script: Binding<SavedScript>, availableScriptNames: [String] = []) {
        self._script = script
        self.availableScriptNames = availableScriptNames
        _currentName = State(initialValue: script.wrappedValue.name)
        _dialogs = State(initialValue: script.wrappedValue.dialogs.map { dialog in
            (image: dialog.image, text: dialog.text, key: dialog.key)
        })
        _conditionalScripts = State(initialValue: script.wrappedValue.conditionalScripts)
    }

    // MARK: - Computed: Lua script (diálogos)

    private func generateScriptKey() -> String {
        let formattedName = currentName.lowercased().replacingOccurrences(of: " ", with: "-")
        let dialogCount = dialogs.filter { $0.key.starts(with: formattedName) }.count + 1
        let numberString = String(format: "%02d", dialogCount)
        return "\(formattedName)-\(numberString)"
    }

    var generatedLuaScript: String {
        """
        {
            name = "\(currentName)",
            dialog = {
                \(dialogs.map { dialog in
                    """
                    {
                        video = '\(dialog.image)',
                        text = "\(dialog.key)",
                    }
                    """
                }.joined(separator: ",\n                "))

            }
        },
        """
    }

    var generatedLocalization: String {
        dialogs.map { dialog in
            """
            "\(dialog.key)" = "\(dialog.text)"
            """
        }.joined(separator: "\n\n")
    }

    // MARK: - Computed: conditionalScripts Lua

    var generatedConditionalScripts: String {
        guard !conditionalScripts.isEmpty else { return "" }
        let lines = conditionalScripts.map { "    \"\($0.conditionString)\"," }
        return "conditionalScripts = {\n\(lines.joined(separator: "\n"))\n}"
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {

            // ── Left Column: outputs ──────────────────────────────────────
            ScrollView {
                VStack(spacing: 12) {

                    // Lua script de diálogos
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

                    // Localization
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

                    // conditionalScripts (solo si hay condiciones)
                    if !conditionalScripts.isEmpty {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Conditional Scripts")
                                        .font(.headline)
                                    Text("(trigger field)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    CopyButton(content: generatedConditionalScripts)
                                }
                                TextEditor(text: .constant(generatedConditionalScripts))
                                    .font(.system(size: 9, design: .monospaced))
                                    .frame(
                                        minHeight: 60,
                                        maxHeight: CGFloat(conditionalScripts.count) * 20 + 40
                                    )
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(width: 400)

            // ── Center Column: diálogos ───────────────────────────────────
            VStack(spacing: 0) {
                // Lista de diálogos
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

                // Selector de imagen
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

                // Nombre del script
                GroupBox("Dialog Name") {
                    TextField("Enter dialog name", text: $currentName)
                        .textFieldStyle(.roundedBorder)
                }

                // Texto del diálogo
                GroupBox("Dialog Text") {
                    TextEditor(text: Binding(
                        get: { currentDialog },
                        set: { newValue in
                            if newValue.count <= 94 {
                                currentDialog = newValue
                            }
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

                // Botón agregar diálogo
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
        .sheet(isPresented: $showConditionals) {
            ConditionalScriptsEditorView(
                conditions: $conditionalScripts,
                availableScriptNames: availableScriptNames
            )
            .frame(minWidth: 800, minHeight: 500)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Condicionales (\(conditionalScripts.count))") {
                    showConditionals = true
                }
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
