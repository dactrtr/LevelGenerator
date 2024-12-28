import SwiftUI

struct TriggerListView: View {
    @Binding var placedItems: [PlacedItem]
    
    var body: some View {
        VStack {
            Text("Placed Triggers")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    let triggerItems = placedItems.filter { $0.itemType == .trigger }
                    ForEach(Array(triggerItems.enumerated()), id: \.element.id) { index, item in
                        TriggerRow(item: item, index: index) {
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

struct TriggerRow: View {
    let item: PlacedItem
    let index: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 24, height: 24)
                Text("\(index + 1)")
                    .foregroundColor(.purple)
                    .font(.system(size: 12, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Trigger \(item.script ?? 0)")
                    .font(.system(.body, design: .rounded))
                Text("(\(Int(item.x)), \(Int(item.y)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(item.width ?? 0))x\(Int(item.height ?? 0))")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.purple)
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