import SwiftUI

struct AddEnemyView: View {
    @Binding var selectedEnemy: String
    @Binding var enemyX: Double
    @Binding var enemyY: Double
    @Binding var placedItems: [PlacedItem]
    @State private var speed: Double = 1.0
    
    let availableEnemies = ["brocorat", "frogcolli"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Control de enemigos")
                .font(.headline)
                .padding(.top)
            
            Picker("Tipo", selection: $selectedEnemy) {
                ForEach(availableEnemies, id: \.self) { enemy in
                    Text(enemy.capitalized)
                        .tag(enemy)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)
            
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
                Image(selectedEnemy)
                    .resizable()
                    .frame(width: selectedEnemy == "frogcolli" ? 40 : 32,
                           height: selectedEnemy == "frogcolli" ? 40 : 32)
                
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
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
} 