import SwiftUI

struct NewLevelSheet: View {
    @ObservedObject var contentStore: ContentStore
    @Environment(\.dismiss) var dismiss
    @State private var levelName = ""
    
    var body: some View {
        Form {
            TextField("Level Name", text: $levelName)
        }
        .navigationTitle("New Level")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    let newLevel = SavedLevel(
                        id: UUID(),
                        name: levelName,
                        level: 1,
                        roomNumber: 1,
                        tile: 1,
                        light: 0.5,
                        shadow: false,
                        doors: SavedLevel.SavedDoors(
                            top: true, right: true, down: true, left: true,
                            topLeadsTo: 1, rightLeadsTo: 1, downLeadsTo: 1, leftLeadsTo: 1
                        ),
                        placedItems: []
                    )
                    contentStore.addLevel(newLevel)
                    dismiss()
                }
                .disabled(levelName.isEmpty)
            }
        }
    }
} 