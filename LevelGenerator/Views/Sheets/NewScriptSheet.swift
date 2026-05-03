import SwiftUI

struct NewScriptSheet: View {
    @ObservedObject var contentStore: ContentStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Script")
                .font(.headline)
            TextField("Script name (kebab-case)", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    contentStore.addScript(SavedScript(name: name))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
