import SwiftUI

struct ContentListView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSection: ContentSection
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingNewScriptSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var selectedLevel: SavedLevel?
    @Binding var selectedScript: SavedScript?
    @State private var showingConnectionMap = false
    
    var body: some View {
        List {
            Picker("Section", selection: $selectedSection) {
                Text("Levels").tag(ContentSection.levels)
                Text("Scripts").tag(ContentSection.scripts)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedSection == .levels {
                ForEach(contentStore.levels.indices, id: \.self) { index in
                    #if os(iOS)
                    NavigationLink {
                        LevelEditorView(level: contentStore.levelBinding(at: index))
                    } label: {
                        LevelRow(level: contentStore.levels[index])
                    }
                    #else
                    LevelRow(level: contentStore.levels[index])
                        .onTapGesture {
                            selectedLevel = contentStore.levels[index]
                        }
                        .background(
                            selectedLevel?.id == contentStore.levels[index].id ?
                                Color.blue.opacity(0.1) : Color.clear
                        )
                    #endif
                }
                .onDelete { indexSet in
                    contentStore.deleteLevel(at: indexSet)
                }
                
                Section {
                    Button {
                        showingConnectionMap = true
                    } label: {
                        Label("View Room Connections", systemImage: "map")
                    }
                }
            } else {
                ForEach(contentStore.scripts.indices, id: \.self) { index in
                    #if os(iOS)
                    NavigationLink {
                        ScriptView(script: contentStore.scriptBinding(at: index))
                    } label: {
                        ScriptRow(script: contentStore.scripts[index])
                    }
                    #else
                    ScriptRow(script: contentStore.scripts[index])
                        .onTapGesture {
                            selectedScript = contentStore.scripts[index]
                        }
                        .background(
                            selectedScript?.id == contentStore.scripts[index].id ?
                                Color.blue.opacity(0.1) : Color.clear
                        )
                    #endif
                }
                .onDelete { indexSet in
                    contentStore.deleteScript(at: indexSet)
                }
            }
        }
        .sheet(isPresented: $showingConnectionMap) {
            NavigationStack {
                RoomConnectionMapView(levels: contentStore.levels, contentStore: contentStore)
                    .navigationTitle("Room Connections")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingConnectionMap = false
                            }
                        }
                    }
            }
        }
    }
}

struct LevelRow: View {
    let level: SavedLevel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(level.name)
                .font(.headline)
            Text("Level \(level.level) - Room \(level.roomNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ScriptRow: View {
    let script: SavedScript
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(script.name)
                .font(.headline)
            Text("\(script.dialogs.count) dialogs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 