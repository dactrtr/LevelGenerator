import SwiftUI

struct MapView: View {
    let placedItems: [PlacedItem]
    let selectedItem: String
    let currentX: Double
    let currentY: Double
    let selectedEnemy: String
    let enemyX: Double
    let enemyY: Double
    let showTriggerPreview: Bool
    let triggerX: Double
    let triggerY: Double
    let triggerWidth: Double
    let triggerHeight: Double
    
    var body: some View {
        ZStack {
            Image("room")
                .resizable()
                .frame(width: 400, height: 240)
            
            Rectangle()
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 400, height: 240)
            
            ForEach(Array(placedItems.filter { $0.itemType != .trigger }.enumerated()), 
                   id: \.element.id) { index, item in
                ZStack {
                    Image(item.type)
                        .resizable()
                        .frame(width: item.size, height: item.size)
                    
                    ZStack {
                        Circle()
                            .fill(item.itemType == .furniture ? Color.green : Color.red)
                            .frame(width: 16, height: 16)
                        Text("\(index + 1)")
                            .foregroundColor(.white)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .offset(x: item.size/2 - 4, y: -item.size/2 + 4)
                }
                .position(x: item.x, y: item.y)
            }
            
            if !showTriggerPreview {
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
            
            if showTriggerPreview {
                Rectangle()
                    .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                    .frame(width: triggerWidth, height: triggerHeight)
                    .position(x: triggerX, y: triggerY)
            }
            
            ForEach(Array(placedItems.filter { $0.itemType == .trigger }.enumerated()), 
                   id: \.element.id) { index, trigger in
                ZStack {
                    Rectangle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: trigger.width ?? 60, height: trigger.height ?? 30)
                        .overlay(
                            Rectangle()
                                .stroke(Color.purple, lineWidth: 1)
                        )
                    
                    ZStack {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 16, height: 16)
                        Text("\(index + 1)")
                            .foregroundColor(.white)
                            .font(.system(size: 10, weight: .bold))
                    }
                }
                .position(x: trigger.x, y: trigger.y)
            }
        }
        .frame(width: 400, height: 240)
        .background(Color.white)
        .clipped()
    }
} 