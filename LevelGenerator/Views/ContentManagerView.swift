import SwiftUI

struct ContentManagerView: View {
    @State private var savedLevels: [SavedLevel] = []
    @State private var savedScripts: [SavedScript] = []
    @State private var selectedSection: ContentSection = .levels
    @State private var showingNewLevelSheet = false
    @State private var showingNewScriptSheet = false
    
    enum ContentSection {
        case levels, scripts
    }
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            List {
                Picker("Section", selection: $selectedSection) {
                    Text("Levels").tag(ContentSection.levels)
                    Text("Scripts").tag(ContentSection.scripts)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedSection == .levels {
                    ForEach(savedLevels.indices, id: \.self) { index in
                        NavigationLink {
                            LevelEditorView(level: $savedLevels[index])
                        } label: {
                            VStack(alignment: .leading) {
                                Text(savedLevels[index].name)
                                    .font(.headline)
                                Text("Level \(savedLevels[index].level) - Room \(savedLevels[index].roomNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        savedLevels.remove(atOffsets: indexSet)
                    }
                } else {
                    ForEach(savedScripts.indices, id: \.self) { index in
                        NavigationLink {
                            ScriptView(script: $savedScripts[index])
                        } label: {
                            VStack(alignment: .leading) {
                                Text(savedScripts[index].name)
                                    .font(.headline)
                                Text("\(savedScripts[index].dialogs.count) dialogs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        savedScripts.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle(selectedSection == .levels ? "Levels" : "Scripts")
            .safeToolbar {
                Button {
                    if selectedSection == .levels {
                        showingNewLevelSheet = true
                    } else {
                        showingNewScriptSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewLevelSheet) {
            NewLevelSheet(savedLevels: $savedLevels)
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NewScriptSheet(savedScripts: $savedScripts)
        }
        #else
        NavigationSplitView {
            List(selection: $selectedSection) {
                Section("Content") {
                    Text("Levels")
                        .tag(ContentSection.levels)
                    Text("Scripts")
                        .tag(ContentSection.scripts)
                }
            }
        } content: {
            List {
                if selectedSection == .levels {
                    ForEach(savedLevels.indices, id: \.self) { index in
                        NavigationLink {
                            LevelEditorView(level: $savedLevels[index])
                        } label: {
                            VStack(alignment: .leading) {
                                Text(savedLevels[index].name)
                                    .font(.headline)
                                Text("Level \(savedLevels[index].level) - Room \(savedLevels[index].roomNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        savedLevels.remove(atOffsets: indexSet)
                    }
                } else {
                    ForEach(savedScripts.indices, id: \.self) { index in
                        NavigationLink {
                            ScriptView(script: $savedScripts[index])
                        } label: {
                            VStack(alignment: .leading) {
                                Text(savedScripts[index].name)
                                    .font(.headline)
                                Text("\(savedScripts[index].dialogs.count) dialogs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        savedScripts.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle(selectedSection == .levels ? "Levels" : "Scripts")
            .safeToolbar {
                Button {
                    if selectedSection == .levels {
                        showingNewLevelSheet = true
                    } else {
                        showingNewScriptSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        } detail: {
            Text("Select a level or script to edit")
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingNewLevelSheet) {
            NewLevelSheet(savedLevels: $savedLevels)
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NewScriptSheet(savedScripts: $savedScripts)
        }
        #endif
    }
}

struct NewLevelSheet: View {
    @Binding var savedLevels: [SavedLevel]
    @Environment(\.dismiss) var dismiss
    @State private var levelName = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Level Name", text: $levelName)
            }
            .navigationTitle("New Level")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let newLevel = SavedLevel(
                            id: UUID(),
                            name: levelName,
                            level: 1,
                            roomNumber: 1,
                            tile: 1,
                            light: 0.5,
                            shadow: false,
                            doors: SavedLevel.SavedDoors(
                                top: true, right: true, down: true, left: true,
                                topLeadsTo: 1, rightLeadsTo: 1, downLeadsTo: 1, leftLeadsTo: 1
                            ),
                            placedItems: []
                        )
                        savedLevels.append(newLevel)
                        dismiss()
                    }
                    .disabled(levelName.isEmpty)
                }
            }
        }
    }
}

struct NewScriptSheet: View {
    @Binding var savedScripts: [SavedScript]
    @Environment(\.dismiss) var dismiss
    @State private var scriptName = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Script Name", text: $scriptName)
            }
            .navigationTitle("New Script")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let newScript = SavedScript(
                            id: UUID(),
                            name: scriptName,
                            dialogs: []
                        )
                        savedScripts.append(newScript)
                        dismiss()
                    }
                    .disabled(scriptName.isEmpty)
                }
            }
        }
    }
}

// Extension para manejar la toolbar de manera segura
extension View {
    func safeToolbar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(macOS)
        self.toolbar {
            ToolbarItemGroup {
                content()
            }
        }
        #else
        self.toolbar {
            content()
        }
        #endif
    }
} 