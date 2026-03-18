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
    @State private var selectedScriptId: UUID?
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var showConditionals = false
    @State private var showingNewTriggerSheet = false
    @State private var showingNewScriptSheet = false
    @State private var showingDeleteAlert = false
    @State private var deletingScriptId: UUID?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // ── Sidebar ───────────────────────────────────────────────────
            List(selection: $selectedSidebarItem) {
                NavigationLink(value: SidebarItem.levels) {
                    Label("Levels", systemImage: "square.stack.3d.up")
                }
                Section("Triggers") {
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
                            } label: {
                                Label("Delete Trigger", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Content")
            .listStyle(.sidebar)
            .toolbar {
                Button {
                    if case .levels = selectedSidebarItem {
                        showingNewLevelSheet = true
                    } else {
                        showingNewTriggerSheet = true
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }

        } content: {
            // ── Content column ────────────────────────────────────────────
            if case .trigger(let triggerId) = selectedSidebarItem,
               contentStore.triggers.contains(where: { $0.id == triggerId }) {

                let trigger = contentStore.triggerBinding(id: triggerId)

                VStack(spacing: 0) {
                    List(selection: $selectedScriptId) {
                        ForEach(trigger.wrappedValue.scripts) { script in
                            NavigationLink(value: script.id) {
                                ScriptRowWithCopyButtons(script: script)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deletingScriptId = script.id
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Script", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { offsets in
                            offsets.forEach { i in
                                let id = trigger.wrappedValue.scripts[i].id
                                contentStore.deleteScript(scriptId: id, from: triggerId)
                            }
                            selectedScriptId = nil
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .navigationTitle(trigger.wrappedValue.name)
                .toolbar {
                    ToolbarItemGroup {
                        Button {
                            showingNewScriptSheet = true
                        } label: {
                            Label("Add Script", systemImage: "plus")
                        }

                        if selectedScriptId != nil {
                            Button(role: .destructive) {
                                deletingScriptId = selectedScriptId
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        Button("Condicionales (\(trigger.wrappedValue.conditionalScripts.count))") {
                            showConditionals = true
                        }

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
                .sheet(isPresented: $showConditionals) {
                    ConditionalScriptsEditorView(
                        conditions: trigger.conditionalScripts,
                        availableScriptNames: trigger.wrappedValue.scripts.map { $0.name }
                    )
                    .frame(minWidth: 800, minHeight: 500)
                }
                .sheet(isPresented: $showingNewScriptSheet) {
                    NewScriptInTriggerSheet { name in
                        contentStore.addScript(SavedScript(name: name), to: triggerId)
                    }
                }
                .alert("Delete Script", isPresented: $showingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        if let id = deletingScriptId {
                            contentStore.deleteScript(scriptId: id, from: triggerId)
                            if selectedScriptId == id { selectedScriptId = nil }
                        }
                        deletingScriptId = nil
                    }
                    Button("Cancel", role: .cancel) { deletingScriptId = nil }
                } message: {
                    Text("This action cannot be undone.")
                }

            } else {
                // Levels list
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
                .toolbar {
                    ToolbarItemGroup {
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

        } detail: {
            // ── Detail column ─────────────────────────────────────────────
            Group {
                if case .levels = selectedSidebarItem {
                    if let selectedId = selectedLevelId,
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
                } else if case .trigger(let triggerId) = selectedSidebarItem {
                    if let selectedId = selectedScriptId,
                       let ti = contentStore.triggers.firstIndex(where: { $0.id == triggerId }),
                       contentStore.triggers[ti].scripts.contains(where: { $0.id == selectedId }) {
                        ScriptView(script: contentStore.scriptBinding(triggerId: triggerId, scriptId: selectedId))
                            .id(selectedId)
                    } else {
                        ContentUnavailableView {
                            Label("No Script Selected", systemImage: "doc.text")
                        } description: {
                            Text("Select a script from the list to edit it")
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Select a Trigger", systemImage: "text.word.spacing")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingNewLevelSheet) {
            NewLevelSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewTriggerSheet) {
            NewTriggerSheet(contentStore: contentStore)
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
