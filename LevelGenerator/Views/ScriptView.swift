import SwiftUI

struct ScriptView: View {
    @Binding var script: SavedScript
    @Environment(\.dismiss) var dismiss
    @State private var selectedImage: String = "player"
    @State private var currentDialog: String = ""
    @State private var currentName: String
    @State private var dialogs: [(image: String, text: String, key: String)]
    
    let availableImages = ["player", "playerWorry", "playerSurprise", "radio", "radiopocket", "radioring", "notes", "playerHappy", "playerAngry"]
    
    // Propiedades públicas para SavedScript
    var scriptName: String { currentName }
    var scriptDialogs: [(image: String, text: String, key: String)] { dialogs }
    
    init(script: Binding<SavedScript>) {
        self._script = script
        _currentName = State(initialValue: script.wrappedValue.name)
        _dialogs = State(initialValue: script.wrappedValue.dialogs.map { dialog in
            (image: dialog.image, text: dialog.text, key: dialog.key)
        })
    }
    
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
            -- trigger \(currentName)
            dialog = {
                \(dialogs.map { dialog in
                    """
                    {
                        video = '\(dialog.image)',
                        text = Graphics.getLocalizedText("\(dialog.key)", "en"),
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
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Column - Script Editors
            VStack {
                // Lua Script
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
                    }
                }
            }
            .frame(width: 400)
            .padding()
            
            // Center Column - Dialog List
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
            .frame(maxWidth: .infinity)
            .background(PlatformColor.background)
            
            // Right Column - Dialog Input
            VStack(spacing: 16) {
                // Image Selector
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
                
                // Name Input
                GroupBox("Dialog Name") {
                    TextField("Enter dialog name", text: $currentName)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Dialog Input
                GroupBox("Dialog Text") {
                    TextEditor(text: Binding(
                        get: { currentDialog },
                        set: { newValue in
                            if newValue.count <= 99 {
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
                                Text("\(currentDialog.count)/99")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(4)
                            }
                        }
                    )
                }
                
                // Add Button
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
