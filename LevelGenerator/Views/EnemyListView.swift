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
                    let enemyItems = placedItems.filter { $0.itemType == .enemy }
                    ForEach(Array(enemyItems.enumerated()), id: \.element.id) { index, item in
                        EnemyRow(item: item, index: index) {
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
    let index: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Círculo con número
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 18, height: 18)
                Text("\(index + 1)")
                    .foregroundColor(.white)
                    .font(.system(size: 11, weight: .bold))
            }
            
            Text(item.type)
            Text("X: \(Int(item.x)), Y: \(Int(item.y))")
            if let speed = item.speed {
                Text("S:\(speed, specifier: "%.1f")")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
            if item.nocollide {
                Text("NC")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
    }
} 