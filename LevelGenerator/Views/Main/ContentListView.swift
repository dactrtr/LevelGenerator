import SwiftUI

struct ContentListView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var selectedLevel: SavedLevel?

    @State private var showTriggers = false
    @State private var showingNewTriggerSheet = false

    var body: some View {
        List {
            Picker("Section", selection: $showTriggers) {
                Text("Levels").tag(false)
                Text("Triggers").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)
            .onChange(of: showTriggers) { _, showing in
                if !showing { selectedSidebarItem = .levels }
            }

            if !showTriggers {
                ForEach(contentStore.levels) { level in
                    #if os(iOS)
                    NavigationLink {
                        LevelEditorView(level: contentStore.levelBinding(id: level.id))
                    } label: {
                        LevelRow(level: level)
                    }
                    #else
                    LevelRow(level: level)
                        .onTapGesture { selectedLevel = level }
                        .background(selectedLevel?.id == level.id ? Color.blue.opacity(0.1) : Color.clear)
                    #endif
                }
                .onDelete { indexSet in
                    contentStore.deleteLevel(at: indexSet)
                }
            } else {
                ForEach(contentStore.triggers) { trigger in
                    #if os(iOS)
                    NavigationLink {
                        TriggerScriptsView(
                            trigger: contentStore.triggerBinding(id: trigger.id),
                            contentStore: contentStore
                        )
                    } label: {
                        Text(trigger.name)
                            .font(.headline)
                    }
                    #else
                    Text(trigger.name)
                    #endif
                }
                .onDelete { offsets in
                    contentStore.deleteTrigger(at: offsets)
                }
            }
        }
        #if os(iOS)
        .navigationTitle("Content")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if !showTriggers {
                        showingNewLevelSheet = true
                    } else {
                        showingNewTriggerSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingExportSheet = true } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    Button { showingImportSheet = true } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingNewTriggerSheet) {
            NavigationStack {
                NewTriggerSheet(contentStore: contentStore)
            }
        }
        #endif
    }
}
