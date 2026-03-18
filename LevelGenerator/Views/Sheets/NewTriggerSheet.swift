import SwiftUI

struct NewTriggerSheet: View {
    @ObservedObject var contentStore: ContentStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Trigger")
                .font(.headline)
            TextField("Trigger name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    contentStore.addTrigger(SavedTrigger(name: name))
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
