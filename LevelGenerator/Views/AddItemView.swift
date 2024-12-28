import SwiftUI

struct AddItemView: View {
    @Binding var selectedItem: String
    @Binding var currentX: Double
    @Binding var currentY: Double
    @Binding var placedItems: [PlacedItem]
    @State private var nocollide: Bool = false
    
    let availableItems = ["chair", "fellchair", "box", "trash", "toxic", "table", "blood", "blood2", "deadrat", "xtree-1", "xtree-2", "xtree-3", "xtree-4"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Item Control")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 12) {
                ForEach(availableItems, id: \.self) { item in
                    Button(action: {
                        selectedItem = item
                    }) {
                        Image(item)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedItem == item ? 
                                         Color.blue.opacity(0.2) : 
                                         PlatformColor.secondaryBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedItem == item ? Color.blue : Color.clear, 
                                           lineWidth: 2)
                            )
                    }
                }
            }
            .padding(.vertical, 4)
            
            GroupBox {
                VStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Posición X: \(Int(currentX))")
                            .font(.subheadline)
                        Slider(value: $currentX, in: 16...384)
                            .accentColor(.blue)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Posición Y: \(Int(currentY))")
                            .font(.subheadline)
                        Slider(value: $currentY, in: 16...224)
                            .accentColor(.blue)
                    }
                }
            }
            
            Toggle("No Collide", isOn: $nocollide)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            HStack {
                Spacer()
                Button(action: {
                    let newItem = PlacedItem(
                        type: selectedItem,
                        x: currentX,
                        y: currentY,
                        itemType: .furniture,
                        nocollide: nocollide
                    )
                    placedItems.append(newItem)
                }) {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        }
        .padding()
    }
} 
