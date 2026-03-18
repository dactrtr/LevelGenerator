import SwiftUI

struct ScriptRowWithCopyButtons: View {
    let script: SavedScript

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(script.name)
                    .font(.headline)
                Text("\(script.dialogs.count) dialogs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Lua") { copy(ScriptLuaGenerator.lua(for: script)) }
                .buttonStyle(.bordered)
            Button("Strings") { copy(ScriptLuaGenerator.localization(for: script)) }
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }

    private func copy(_ string: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #else
        UIPasteboard.general.string = string
        #endif
    }
}
