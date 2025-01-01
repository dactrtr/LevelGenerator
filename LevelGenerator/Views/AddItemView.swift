import SwiftUI

struct AddItemView: View {
    @Binding var selectedItem: String
    @Binding var currentX: Double
    @Binding var currentY: Double
    @Binding var placedItems: [PlacedItem]
    @State private var nocollide: Bool = false
    
    let items = ["chair","fellchair", "table", "box", "trash", "blood", "blood2", "toxic", "xtree-1", "xtree-2", "xtree-3", "xtree-4","microwave","gifts","gift"]
    let columns = Array(repeating: GridItem(.fixed(48), spacing: 8), count: 8) // 8 items por página
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Items Grid with Paging
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.fixed(48))], spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            Image(item)
                                .resizable()
                                .frame(width: 32, height: 32)
                                .padding(8)
                                .background(selectedItem == item ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .frame(height: 64)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .frame(maxWidth: .infinity)
            .scrollTargetBehavior(.paging)
            
            // No Collide Toggle
            Toggle(isOn: $nocollide) {
                Text("No Collide")
                    .font(.footnote)
            }
            
            // Add Button
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
                Label("Add", systemImage: "plus")
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.small)
            
            // Position Control Grid
            ControlGrid(x: $currentX, y: $currentY, width: 400, height: 240)
                .frame(height: 120)
                .cornerRadius(8)
        }
        .padding(12)
    }
} 
