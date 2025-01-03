import SwiftUI

struct AddItemView: View {
    @Binding var selectedItem: String
    @Binding var currentX: Double
    @Binding var currentY: Double
    @Binding var placedItems: [PlacedItem]
    
    let items = ["notes", "radio", "lamp", "keycard"] // Items disponibles
    let columns = Array(repeating: GridItem(.fixed(48), spacing: 8), count: 8)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.fixed(48))], spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            Image(item)
                                .resizable()
                                .frame(width: 48, height: 48)
                                .padding(8)
                                .background(selectedItem == item ? Color.purple.opacity(0.2) : Color.clear)
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
            
            Button {
                placedItems.append(
                    PlacedItem(
                        type: selectedItem,
                        x: currentX,
                        y: currentY,
                        itemType: .item
                    )
                )
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.small)
            
            ControlGrid(x: $currentX, y: $currentY, width: 400, height: 240)
                .frame(height: 120)
                .cornerRadius(8)
        }
        .padding(12)
    }
}
