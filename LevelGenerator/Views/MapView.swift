import SwiftUI

struct MapView: View {
    let placedItems: [PlacedItem]
    let selectedItem: String
    let currentX: Double
    let currentY: Double
    let selectedEnemy: String
    let enemyX: Double
    let enemyY: Double
    
    var body: some View {
        ZStack {
            Image("room")
                .resizable()
                .frame(width: 400, height: 240)
            
            Rectangle()
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 400, height: 240)
            
            ForEach(placedItems) { item in
                Image(item.type)
                    .resizable()
                    .frame(width: item.size, height: item.size)
                    .position(x: item.x, y: item.y)
            }
            
            Image(selectedItem)
                .resizable()
                .frame(width: 32, height: 32)
                .position(x: currentX, y: currentY)
            
            Image(selectedEnemy)
                .resizable()
                .frame(width: selectedEnemy == "frogcolli" ? 40 : 32,
                       height: selectedEnemy == "frogcolli" ? 40 : 32)
                .position(x: enemyX, y: enemyY)
        }
        .frame(width: 400, height: 240)
        .background(Color.white)
        .clipped()
    }
} 