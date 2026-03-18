import SwiftUI

struct NewScriptInTriggerSheet: View {
    @Environment(\.dismiss) var dismiss
    var onConfirm: (String) -> Void
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Script")
                .font(.headline)
            TextField("Script name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    onConfirm(name)
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
