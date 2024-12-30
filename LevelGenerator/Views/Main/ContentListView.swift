import SwiftUI

struct ContentListView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSection: ContentSection
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingNewScriptSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    
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
                    NavigationLink {
                        LevelEditorView(level: contentStore.levelBinding(at: index))
                    } label: {
                        VStack(alignment: .leading) {
                            Text(contentStore.levels[index].name)
                                .font(.headline)
                            Text("Level \(contentStore.levels[index].level) - Room \(contentStore.levels[index].roomNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    contentStore.deleteLevel(at: indexSet)
                }
            } else {
                ForEach(contentStore.scripts.indices, id: \.self) { index in
                    NavigationLink {
                        ScriptView(script: contentStore.scriptBinding(at: index))
                    } label: {
                        VStack(alignment: .leading) {
                            Text(contentStore.scripts[index].name)
                                .font(.headline)
                            Text("\(contentStore.scripts[index].dialogs.count) dialogs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    contentStore.deleteScript(at: indexSet)
                }
            }
        }
        .navigationTitle(selectedSection == .levels ? "Levels" : "Scripts")
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
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
    }
} 