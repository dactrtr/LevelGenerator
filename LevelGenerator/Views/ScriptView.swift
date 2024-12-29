import SwiftUI

struct ScriptView: View {
    @State private var selectedImage: String = "player"
    @State private var currentDialog: String = ""
    @State private var currentName: String = ""
    @State private var currentScriptKey: String = ""
    @State private var dialogs: [(image: String, text: String, key: String)] = []
    
    let availableImages = ["player", "playerWorry", "playerSurprise", "radio", "radiopocket", "radioring", "notes"]
    
    var generatedLuaScript: String {
        """
        {
            -- trigger mess
            dialog = {
                name = "\(currentName)",
                script = {
                    \(dialogs.map { dialog in
                        """
                        {
                            video = '\(dialog.image)',
                            text = Graphics.getLocalizedText("\(dialog.key)", "en"),
                        }
                        """
                    }.joined(separator: ",\n                    "))
                }
            }
        }
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
                GroupBox("Generated Lua Script") {
                    TextEditor(text: .constant(generatedLuaScript))
                        .font(.system(size: 9, design: .monospaced))
                }
                
                // Localization
                GroupBox("Generated Localization") {
                    TextEditor(text: .constant(generatedLocalization))
                        .font(.system(size: 9, design: .monospaced))
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
                
                // Script Key Input
                GroupBox("Script Key") {
                    TextField("Enter script key", text: $currentScriptKey)
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
                    if !currentDialog.isEmpty && !currentName.isEmpty && !currentScriptKey.isEmpty {
                        dialogs.append((
                            image: selectedImage,
                            text: currentDialog,
                            key: currentScriptKey
                        ))
                        currentDialog = ""
                        currentScriptKey = ""
                    }
                } label: {
                    Text("Add Dialog")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentDialog.isEmpty || currentName.isEmpty || currentScriptKey.isEmpty)
                
                Spacer()
            }
            .frame(width: 300)
            .padding()
            .background(PlatformColor.groupedBackground)
        }
    }
} 