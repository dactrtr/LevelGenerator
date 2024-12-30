import SwiftUI

struct NewScriptSheet: View {
    @ObservedObject var contentStore: ContentStore
    @Environment(\.dismiss) var dismiss
    @State private var scriptName = ""
    @State private var showingTriggerScripts = false
    
    var triggerScripts: [RoomScripts] {
        contentStore.getTriggerScripts()
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Script Name", text: $scriptName)
            }
            
            if !triggerScripts.isEmpty {
                ForEach(triggerScripts) { roomScripts in
                    Section(roomScripts.title) {
                        ForEach(roomScripts.scripts) { info in
                            Button {
                                scriptName = info.name
                            } label: {
                                HStack {
                                    Text(info.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if scriptName == info.name {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("New Script")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    let newScript = SavedScript(
                        id: UUID(),
                        name: scriptName,
                        dialogs: []
                    )
                    contentStore.addScript(newScript)
                    dismiss()
                }
                .disabled(scriptName.isEmpty)
            }
        }
    }
} 