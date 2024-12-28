import SwiftUI

struct AddItemView: View {
    @Binding var selectedItem: String
    @Binding var currentX: Double
    @Binding var currentY: Double
    @Binding var placedItems: [PlacedItem]
    @State private var nocollide: Bool = false
    
    let items = ["chair", "table", "box", "trash", "blood", "blood2", "toxic", "deadrat"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.headline)
                .padding(.top, 8)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 48, maximum: 48), spacing: 8)
            ], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        Image(item)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedItem == item ? 
                                         Color.blue.opacity(0.2) : 
                                         PlatformColor.secondaryBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedItem == item ? Color.blue : Color.clear, 
                                           lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            GroupBox {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Position X")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $currentX, in: 16...384)
                            .tint(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Position Y")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $currentY, in: 16...224)
                            .tint(.blue)
                    }
                }
            }
            
            Toggle("No Collide", isOn: $nocollide)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            Button {
                placedItems.append(
                    PlacedItem(
                        type: selectedItem,
                        x: currentX,
                        y: currentY,
                        itemType: .furniture,
                        nocollide: nocollide
                    )
                )
            } label: {
                Label("Add Item", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding(12)
    }
} 
