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
                    let furnitureItems = placedItems.filter { $0.itemType == .furniture }
                    ForEach(Array(furnitureItems.enumerated()), id: \.element.id) { index, item in
                        ItemRow(item: item, index: index) {
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
    let index: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Círculo con número
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 18, height: 18)
                Text("\(index + 1)")
                    .foregroundColor(.white)
                    .font(.system(size: 11, weight: .bold))
            }
            
            Text(item.type)
            Text("X: \(Int(item.x)), Y: \(Int(item.y))")
            if item.nocollide {
                Text("NC")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
} 