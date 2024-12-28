import SwiftUI

struct AddEnemyView: View {
    @Binding var selectedEnemy: String
    @Binding var enemyX: Double
    @Binding var enemyY: Double
    @Binding var placedItems: [PlacedItem]
    @State private var speed: Double = 1.0
    
    let availableEnemies = ["brocorat", "frogcolli"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enemy Control")
                .font(.headline)
                .padding(.top)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 56, maximum: 56), spacing: 8)
            ], spacing: 8) {
                ForEach(availableEnemies, id: \.self) { enemy in
                    Button(action: {
                        selectedEnemy = enemy
                    }) {
                        Image(enemy)
                            .resizable()
                            .frame(width: enemy == "frogcolli" ? 40 : 32,
                                   height: enemy == "frogcolli" ? 40 : 32)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedEnemy == enemy ? 
                                         Color.red.opacity(0.2) : 
                                         PlatformColor.secondaryBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedEnemy == enemy ? Color.red : Color.clear, 
                                           lineWidth: 2)
                            )
                    }
                }
            }
            .padding(.vertical, 4)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("X: \(Int(enemyX))")
                    Slider(value: $enemyX, in: 16...384)
                }
                
                VStack(alignment: .leading) {
                    Text("Y: \(Int(enemyY))")
                    Slider(value: $enemyY, in: 16...224)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Speed: \(speed, specifier: "%.1f")")
                Slider(value: $speed, in: 0.1...5.0)
            }
            
            HStack {
                Spacer()
                Button(action: {
                    let newItem = PlacedItem(
                        type: selectedEnemy,
                        x: enemyX,
                        y: enemyY,
                        itemType: .enemy,
                        speed: speed
                    )
                    placedItems.append(newItem)
                }) {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                Spacer()
            }
        }
        .padding()
    }
} 