#if os(iOS)
import SwiftUI

struct iOSContentView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var importText: String
    @Binding var showingImportAlert: Bool
    @Binding var importAlertMessage: String

    var body: some View {
        NavigationStack {
            List {
                Section("Levels") {
                    ForEach(contentStore.levels) { level in
                        NavigationLink {
                            LevelEditorView(level: contentStore.levelBinding(id: level.id))
                        } label: {
                            LevelRow(level: level)
                        }
                    }
                    .onDelete { indexSet in
                        contentStore.deleteLevel(at: indexSet)
                    }
                }
                Section("Triggers") {
                    ForEach(contentStore.triggers) { trigger in
                        NavigationLink {
                            TriggerDetailView(contentStore: contentStore, triggerId: trigger.id)
                        } label: {
                            Text(trigger.name)
                        }
                    }
                }
            }
            .navigationTitle("Content")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewLevelSheet = true
                    } label: {
                        Label("Add Level", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewLevelSheet) {
            NavigationStack {
                NewLevelSheet(contentStore: contentStore)
            }
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

struct TriggerDetailView: View {
    @ObservedObject var contentStore: ContentStore
    let triggerId: UUID

    var body: some View {
        let trigger = contentStore.triggerBinding(id: triggerId)
        List {
            ForEach(trigger.wrappedValue.scripts) { script in
                NavigationLink {
                    ScriptView(script: contentStore.scriptBinding(triggerId: triggerId, scriptId: script.id))
                } label: {
                    Text(script.name)
                }
            }
        }
        .navigationTitle(trigger.wrappedValue.name)
    }
}
#endif
