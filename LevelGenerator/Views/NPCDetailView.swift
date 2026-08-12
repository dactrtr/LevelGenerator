import SwiftUI

struct NPCDetailView: View {
    @Binding var npc: SavedNPC
    let availableScriptNames: [String]
    @State private var showConditionals = false

    private var generatedLua: String {
        ScriptLuaGenerator.lua(for: npc)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                GroupBox("Nombre") {
                    TextField("Nombre", text: $npc.name)
                        .textFieldStyle(.roundedBorder)
                }

                Button("Condicionales (\(npc.conditionalScripts.count))") {
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
                            .frame(minHeight: 120)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showConditionals) {
            ConditionalScriptsEditorView(
                conditions: $npc.conditionalScripts,
                availableScriptNames: availableScriptNames
            )
            .frame(minWidth: 800, minHeight: 500)
        }
    }
}
