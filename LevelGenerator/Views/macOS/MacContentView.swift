#if os(macOS)
import SwiftUI

struct MacContentView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var importText: String
    @Binding var showingImportAlert: Bool
    @Binding var importAlertMessage: String

    @State private var selectedLevelId: UUID?
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var showingNewScriptSheet = false
    @State private var showingNewTriggerSheet = false
    @State private var showingNewNPCSheet = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // ── Sidebar ───────────────────────────────────────────────────
            List(selection: $selectedSidebarItem) {

                Section {
                    NavigationLink(value: SidebarItem.levels) {
                        Label("Levels", systemImage: "square.stack.3d.up")
                    }
                } header: {
                    HStack {
                        Text("Levels")
                        Spacer()
                        Button { showingNewLevelSheet = true } label: { Image(systemName: "plus") }
                            .buttonStyle(.plain)
                    }
                }

                Section {
                    ForEach(contentStore.scripts) { script in
                        NavigationLink(value: SidebarItem.script(script.id)) {
                            Text(script.name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                if let i = contentStore.scripts.firstIndex(where: { $0.id == script.id }) {
                                    contentStore.deleteScript(at: IndexSet([i]))
                                    selectedSidebarItem = .levels
                                }
                            } label: { Label("Delete Script", systemImage: "trash") }
                        }
                    }
                } header: {
                    HStack {
                        Text("Scripts")
                        Spacer()
                        Button { showingNewScriptSheet = true } label: { Image(systemName: "plus") }
                            .buttonStyle(.plain)
                    }
                }

                Section {
                    ForEach(contentStore.triggers) { trigger in
                        NavigationLink(value: SidebarItem.trigger(trigger.id)) {
                            Text(trigger.name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                if let i = contentStore.triggers.firstIndex(where: { $0.id == trigger.id }) {
                                    contentStore.deleteTrigger(at: IndexSet([i]))
                                    selectedSidebarItem = .levels
                                }
                            } label: { Label("Delete Trigger", systemImage: "trash") }
                        }
                    }
                } header: {
                    HStack {
                        Text("Triggers")
                        Spacer()
                        Button { showingNewTriggerSheet = true } label: { Image(systemName: "plus") }
                            .buttonStyle(.plain)
                    }
                }

                Section {
                    ForEach(contentStore.npcs) { npc in
                        NavigationLink(value: SidebarItem.npc(npc.id)) {
                            Text(npc.name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                if let i = contentStore.npcs.firstIndex(where: { $0.id == npc.id }) {
                                    contentStore.deleteNPC(at: IndexSet([i]))
                                    selectedSidebarItem = .levels
                                }
                            } label: { Label("Delete NPC", systemImage: "trash") }
                        }
                    }
                } header: {
                    HStack {
                        Text("NPCs")
                        Spacer()
                        Button { showingNewNPCSheet = true } label: { Image(systemName: "plus") }
                            .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Content")
            .listStyle(.sidebar)

        } content: {
            // ── Content column ────────────────────────────────────────────
            switch selectedSidebarItem {

            case .script(let scriptId)
                where contentStore.scripts.contains(where: { $0.id == scriptId }):
                ScriptView(script: contentStore.scriptBinding(id: scriptId))
                    .id(scriptId)
                    .toolbar {
                        exportImportMenu
                    }

            case .trigger(let triggerId)
                where contentStore.triggers.contains(where: { $0.id == triggerId }):
                TriggerDetailView(
                    trigger: contentStore.triggerBinding(id: triggerId),
                    availableScriptNames: contentStore.scripts.map { $0.name }
                )
                .id(triggerId)
                .navigationTitle(contentStore.triggers.first(where: { $0.id == triggerId })?.name ?? "")
                .toolbar { exportImportMenu }

            case .npc(let npcId)
                where contentStore.npcs.contains(where: { $0.id == npcId }):
                NPCDetailView(
                    npc: contentStore.npcBinding(id: npcId),
                    availableScriptNames: contentStore.scripts.map { $0.name }
                )
                .id(npcId)
                .navigationTitle(contentStore.npcs.first(where: { $0.id == npcId })?.name ?? "")
                .toolbar { exportImportMenu }

            default:
                List(selection: $selectedLevelId) {
                    ForEach(contentStore.levels) { level in
                        NavigationLink(value: level.id) {
                            LevelRow(level: level)
                        }
                    }
                    .onDelete { indexSet in
                        contentStore.deleteLevel(at: indexSet)
                        selectedLevelId = nil
                    }
                }
                .navigationTitle("Levels")
                .toolbar { exportImportMenu }
            }

        } detail: {
            // ── Detail column — only used for level editor ─────────────────
            if case .levels = selectedSidebarItem,
               let selectedId = selectedLevelId,
               contentStore.levels.contains(where: { $0.id == selectedId }) {
                LevelEditorView(level: contentStore.levelBinding(id: selectedId))
                    .id(selectedId)
            } else {
                ContentUnavailableView {
                    Label("No Level Selected", systemImage: "square.stack.3d.up")
                } description: {
                    Text("Select a level from the list to edit it")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingNewLevelSheet) {
            NewLevelSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NewScriptSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewTriggerSheet) {
            NewTriggerSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewNPCSheet) {
            NewNPCSheet(contentStore: contentStore)
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

    @ToolbarContentBuilder
    private var exportImportMenu: some ToolbarContent {
        ToolbarItem {
            Menu {
                Button { showingExportSheet = true } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                Button { showingImportSheet = true } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }
}
#endif
