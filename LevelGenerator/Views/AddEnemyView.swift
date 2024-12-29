import SwiftUI

struct AddEnemyView: View {
    @Binding var selectedEnemy: String
    @Binding var enemyX: Double
    @Binding var enemyY: Double
    @Binding var enemySpeed: Double
    @Binding var placedItems: [PlacedItem]
    
    let enemies = ["brocorat", "frogcolli"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enemy Grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 48, maximum: 48), spacing: 8)
            ], spacing: 8) {
                ForEach(enemies, id: \.self) { enemy in
                    Button {
                        selectedEnemy = enemy
                    } label: {
                        Image(enemy)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .padding(8)
                            .background(selectedEnemy == enemy ? Color.red.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Speed control
            VStack(alignment: .leading, spacing: 4) {
                Text("Speed")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Slider(value: $enemySpeed, in: 0.5...2.0)
                    .tint(.red)
            }
            
            Button {
                placedItems.append(
                    PlacedItem(
                        type: selectedEnemy,
                        x: enemyX,
                        y: enemyY,
                        itemType: .enemy,
                        speed: enemySpeed
                    )
                )
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.small)
            
            // Control Grid al final
            ControlGrid(x: $enemyX, y: $enemyY, width: 400, height: 240)
                .frame(height: 120)
                .cornerRadius(8)
        }
        .padding(12)
    }
} 