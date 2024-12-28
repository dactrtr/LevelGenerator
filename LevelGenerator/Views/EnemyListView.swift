import SwiftUI

struct EnemyListView: View {
    @Binding var placedItems: [PlacedItem]
    
    var body: some View {
        VStack {
            Text("Placed Enemies")
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 24, height: 24)
                Text("\(index + 1)")
                    .foregroundColor(.red)
                    .font(.system(size: 12, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.type.capitalized)
                    .font(.system(.body, design: .rounded))
                Text("(\(Int(item.x)), \(Int(item.y)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let speed = item.speed {
                Text("S:\(speed, specifier: "%.1f")")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Button(action: onDelete) {
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