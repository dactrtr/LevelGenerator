import SwiftUI

struct TriggerScriptsView: View {
    @Binding var trigger: SavedTrigger
    @ObservedObject var contentStore: ContentStore
    @State private var showConditionals = false
    @State private var showingNewScriptSheet = false

    var body: some View {
        List {
            ForEach(trigger.scripts) { script in
                NavigationLink {
                    ScriptView(script: contentStore.scriptBinding(triggerId: trigger.id, scriptId: script.id))
                } label: {
                    ScriptRowWithCopyButtons(script: script)
                }
            }
            .onDelete { offsets in
                offsets.forEach { i in
                    let id = trigger.scripts[i].id
                    contentStore.deleteScript(scriptId: id, from: trigger.id)
                }
            }
        }
        .navigationTitle(trigger.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingNewScriptSheet = true } label: {
                    Image(systemName: "plus")
                }
                Button("Cond. (\(trigger.conditionalScripts.count))") {
                    showConditionals = true
                }
            }
        }
        .sheet(isPresented: $showConditionals) {
            ConditionalScriptsEditorView(
                conditions: $trigger.conditionalScripts,
                availableScriptNames: trigger.scripts.map { $0.name }
            )
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NavigationStack {
                NewScriptInTriggerSheet { name in
                    contentStore.addScript(SavedScript(name: name), to: trigger.id)
                }
            }
        }
    }
}
