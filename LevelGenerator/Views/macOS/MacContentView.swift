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
    
    var body: some View {
        NavigationSplitView {
            ContentListView(
                contentStore: contentStore,
                selectedSection: $selectedSection,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingNewScriptSheet: $showingNewScriptSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet,
                selectedLevel: Binding(
                    get: { selectedLevel },
                    set: { newValue in
                        selectedLevel = newValue
                    }
                ),
                selectedScript: Binding(
                    get: { selectedScript },
                    set: { newValue in
                        selectedScript = newValue
                    }
                )
            )
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
            }
        } detail: {
            if selectedSection == .levels {
                if let levelIndex = selectedLevel.flatMap({ level in
                    contentStore.levels.firstIndex(where: { $0.id == level.id })
                }) {
                    LevelEditorView(level: contentStore.levelBinding(at: levelIndex))
                } else {
                    Text("Select a level")
                        .foregroundColor(.secondary)
                }
            } else {
                if let scriptIndex = selectedScript.flatMap({ script in
                    contentStore.scripts.firstIndex(where: { $0.id == script.id })
                }) {
                    ScriptView(script: contentStore.scriptBinding(at: scriptIndex))
                } else {
                    Text("Select a script")
                        .foregroundColor(.secondary)
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