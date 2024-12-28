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
            Text("Enemies")
                .font(.headline)
                .padding(.top, 8)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 48, maximum: 48), spacing: 8)
            ], spacing: 8) {
                ForEach(enemies, id: \.self) { enemy in
                    Button {
                        selectedEnemy = enemy
                    } label: {
                        Image(enemy)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedEnemy == enemy ? 
                                         Color.red.opacity(0.2) : 
                                         PlatformColor.secondaryBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedEnemy == enemy ? Color.red : Color.clear, 
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
                        Slider(value: $enemyX, in: 16...384)
                            .tint(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Position Y")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $enemyY, in: 16...224)
                            .tint(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $enemySpeed, in: 0.5...2.0)
                            .tint(.red)
                    }
                }
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
                Label("Add Enemy", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(12)
    }
} 