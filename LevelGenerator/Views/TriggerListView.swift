import SwiftUI

struct TriggerListView: View {
    @Binding var placedItems: [PlacedItem]
    
    var triggerItems: [PlacedItem] {
        placedItems.filter { $0.itemType == .trigger }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(triggerItems.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Trigger \(index + 1)")
                                .font(.headline)
                            
                            Text("Position: (\(Int(item.x)), \(Int(item.y)))")
                                .font(.caption)
                            
                            Text("Size: \(Int(item.width ?? 60))×\(Int(item.height ?? 30))")
                                .font(.caption)
                            
                            if let script = item.script {
                                Text("Script: \(script)")
                                    .font(.caption)
                            }
                            
                            if let triggerType = item.triggerType {
                                Text("Type: \(triggerType)")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            if let index = placedItems.firstIndex(where: { $0.id == item.id }) {
                                placedItems.remove(at: index)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(PlatformColor.secondaryBackground)
                    .cornerRadius(8)
                    .padding(.horizontal, 8)
                }
            }
        }
    }
} 
