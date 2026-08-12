import SwiftUI

struct NewNPCSheet: View {
    @ObservedObject var contentStore: ContentStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New NPC")
                .font(.headline)
            TextField("NPC name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    contentStore.addNPC(SavedNPC(name: name))
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
