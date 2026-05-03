import SwiftUI

struct ContentListView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var selectedLevel: SavedLevel?

    enum Section: String, CaseIterable {
        case levels = "Levels"
        case scripts = "Scripts"
        case triggers = "Triggers"
        case npcs = "NPCs"
    }

    @State private var activeSection: Section = .levels
    @State private var showingNewTriggerSheet = false
    @State private var showingNewScriptSheet = false
    @State private var showingNewNPCSheet = false

    var body: some View {
        List {
            Picker("Section", selection: $activeSection) {
                ForEach(Section.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)

            switch activeSection {
            case .levels:
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
                .onDelete { contentStore.deleteLevel(at: $0) }

            case .scripts:
                ForEach(contentStore.scripts) { script in
                    #if os(iOS)
                    NavigationLink {
                        ScriptView(script: contentStore.scriptBinding(id: script.id))
                    } label: {
                        Text(script.name).font(.headline)
                    }
                    #else
                    Text(script.name)
                    #endif
                }
                .onDelete { contentStore.deleteScript(at: $0) }

            case .triggers:
                ForEach(contentStore.triggers) { trigger in
                    #if os(iOS)
                    NavigationLink {
                        TriggerDetailView(
                            trigger: contentStore.triggerBinding(id: trigger.id),
                            availableScriptNames: contentStore.scripts.map { $0.name }
                        )
                    } label: {
                        Text(trigger.name).font(.headline)
                    }
                    #else
                    Text(trigger.name)
                    #endif
                }
                .onDelete { contentStore.deleteTrigger(at: $0) }

            case .npcs:
                ForEach(contentStore.npcs) { npc in
                    #if os(iOS)
                    NavigationLink {
                        NPCDetailView(
                            npc: contentStore.npcBinding(id: npc.id),
                            availableScriptNames: contentStore.scripts.map { $0.name }
                        )
                    } label: {
                        Text(npc.name).font(.headline)
                    }
                    #else
                    Text(npc.name)
                    #endif
                }
                .onDelete { contentStore.deleteNPC(at: $0) }
            }
        }
        #if os(iOS)
        .navigationTitle("Content")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    switch activeSection {
                    case .levels: showingNewLevelSheet = true
                    case .scripts: showingNewScriptSheet = true
                    case .triggers: showingNewTriggerSheet = true
                    case .npcs: showingNewNPCSheet = true
                    }
                } label: { Image(systemName: "plus") }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingExportSheet = true } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    Button { showingImportSheet = true } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NavigationStack { NewScriptSheet(contentStore: contentStore) }
        }
        .sheet(isPresented: $showingNewTriggerSheet) {
            NavigationStack { NewTriggerSheet(contentStore: contentStore) }
        }
        .sheet(isPresented: $showingNewNPCSheet) {
            NavigationStack { NewNPCSheet(contentStore: contentStore) }
        }
        #endif
    }
}
