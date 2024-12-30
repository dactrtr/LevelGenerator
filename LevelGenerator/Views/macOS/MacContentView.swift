#if os(macOS)
import SwiftUI

struct MacContentView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSection: ContentSection
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingNewScriptSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var importText: String
    @Binding var showingImportAlert: Bool
    @Binding var importAlertMessage: String
    
    @State private var selectedLevel: SavedLevel?
    @State private var selectedScript: SavedScript?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showingConnectionMap = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(selection: $selectedSection) {
                Text("Levels")
                    .tag(ContentSection.levels)
                Text("Scripts")
                    .tag(ContentSection.scripts)
            }
        } content: {
            // Content List
            List {
                if selectedSection == .levels {
                    ForEach(contentStore.levels) { level in
                        LevelRow(level: level)
                            .onTapGesture {
                                selectedLevel = level
                                selectedScript = nil
                            }
                            .background(
                                selectedLevel?.id == level.id ?
                                    Color.accentColor.opacity(0.1) : Color.clear
                            )
                    }
                    .onDelete { indexSet in
                        contentStore.deleteLevel(at: indexSet)
                        if selectedLevel != nil {
                            selectedLevel = nil
                        }
                    }
                    
                    Section {
                        Button {
                            showingConnectionMap = true
                        } label: {
                            Label("View Room Connections", systemImage: "map")
                        }
                    }
                } else {
                    ForEach(contentStore.scripts) { script in
                        ScriptRow(script: script)
                            .onTapGesture {
                                selectedScript = script
                                selectedLevel = nil
                            }
                            .background(
                                selectedScript?.id == script.id ?
                                    Color.accentColor.opacity(0.1) : Color.clear
                            )
                    }
                    .onDelete { indexSet in
                        contentStore.deleteScript(at: indexSet)
                        if selectedScript != nil {
                            selectedScript = nil
                        }
                    }
                }
            }
            .navigationTitle(selectedSection == .levels ? "Levels" : "Scripts")
            .toolbar {
                ToolbarItem {
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
                
                ToolbarItem {
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
                }
            }
        } detail: {
            // Detail View
            Group {
                if selectedSection == .levels {
                    if let level = selectedLevel,
                       let index = contentStore.levels.firstIndex(where: { $0.id == level.id }) {
                        LevelEditorView(level: contentStore.levelBinding(at: index))
                    } else {
                        Text("Select a level")
                            .foregroundColor(.secondary)
                    }
                } else {
                    if let script = selectedScript,
                       let index = contentStore.scripts.firstIndex(where: { $0.id == script.id }) {
                        ScriptView(script: contentStore.scriptBinding(at: index))
                    } else {
                        Text("Select a script")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .sheet(isPresented: $showingNewLevelSheet) {
            NewLevelSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NewScriptSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(contentStore: contentStore, isPresented: $showingExportSheet)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView(
                contentStore: contentStore,
                isPresented: $showingImportSheet,
                importText: $importText,
                showingAlert: $showingImportAlert,
                alertMessage: $importAlertMessage
            )
        }
    }
}
#endif 