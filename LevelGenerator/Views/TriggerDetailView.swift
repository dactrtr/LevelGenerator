import SwiftUI

struct TriggerDetailView: View {
    @Binding var trigger: SavedTrigger
    let availableScriptNames: [String]
    @State private var showConditionals = false

    private let triggerTypes = ["Story", "Cutscene", "Search", "Call", "Counter"]

    private var generatedLua: String {
        ScriptLuaGenerator.lua(for: trigger)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                GroupBox("Nombre") {
                    TextField("Nombre", text: $trigger.name)
                        .textFieldStyle(.roundedBorder)
                }

                GroupBox("Tipo") {
                    HStack(spacing: 8) {
                        Button("nil") { trigger.triggerType = nil }
                            .buttonStyle(.bordered)
                            .tint(trigger.triggerType == nil ? .accentColor : nil)
                            .fontWeight(trigger.triggerType == nil ? .semibold : .regular)
                        ForEach(triggerTypes, id: \.self) { type in
                            Button(type) { trigger.triggerType = type }
                                .buttonStyle(.bordered)
                                .tint(trigger.triggerType == type ? .accentColor : nil)
                                .fontWeight(trigger.triggerType == type ? .semibold : .regular)
                        }
                    }
                }

                GroupBox("Fallback Script") {
                    if availableScriptNames.isEmpty {
                        TextField("Script name", text: Binding(
                            get: { trigger.fallbackScript ?? "" },
                            set: { trigger.fallbackScript = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    } else {
                        Menu(trigger.fallbackScript ?? "Sin fallback") {
                            Button("Sin fallback") { trigger.fallbackScript = nil }
                            ForEach(availableScriptNames, id: \.self) { name in
                                Button(name) { trigger.fallbackScript = name }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Button("Condicionales (\(trigger.conditionalScripts.count))") {
                    showConditionals = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Lua").font(.headline)
                            Spacer()
                            CopyButton(content: generatedLua)
                        }
                        TextEditor(text: .constant(generatedLua))
                            .font(.system(size: 9, design: .monospaced))
                            .frame(minHeight: 160)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showConditionals) {
            ConditionalScriptsEditorView(
                conditions: $trigger.conditionalScripts,
                availableScriptNames: availableScriptNames
            )
            .frame(minWidth: 800, minHeight: 500)
        }
    }
}
