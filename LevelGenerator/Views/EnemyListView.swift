import SwiftUI

struct EnemyListView: View {
    @Binding var placedItems: [PlacedItem]
    
    var body: some View {
        VStack {
            Text("Enemigos colocados")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(placedItems.filter { $0.itemType == .enemy }) { item in
                        EnemyRow(item: item) {
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

struct EnemyRow: View {
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
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
    }
} 