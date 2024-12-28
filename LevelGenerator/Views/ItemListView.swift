import SwiftUI

struct ItemListView: View {
    @Binding var placedItems: [PlacedItem]
    
    var body: some View {
        VStack {
            Text("Muebles colocados")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(placedItems.filter { $0.itemType == .furniture }) { item in
                        ItemRow(item: item) {
                            if let index = placedItems.firstIndex(where: { $0.id == item.id }) {
                                placedItems.remove(at: index)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
        }
    }
}

struct ItemRow: View {
    let item: PlacedItem
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(item.type)
                .resizable()
                .frame(width: item.size, height: item.size)
            Text(item.type)
            Text("X: \(Int(item.x)), Y: \(Int(item.y))")
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
} 