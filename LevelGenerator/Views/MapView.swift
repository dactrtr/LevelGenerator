import SwiftUI

struct MapView: View {
    let placedItems: [PlacedItem]
    let selectedProp: String
    let selectedGameItem: String
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
    let doorTop: Bool
    let doorRight: Bool
    let doorDown: Bool
    let doorLeft: Bool
    let doorTopLeadsTo: Int
    let doorRightLeadsTo: Int
    let doorDownLeadsTo: Int
    let doorLeftLeadsTo: Int
    let level: Int
    let selectedMode: ControlMode
    
    var body: some View {
        ZStack {
            Image("room")
                .resizable()
                .frame(width: 400, height: 240)
            
            Rectangle()
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 400, height: 240)
            
            ForEach(Array(placedItems.enumerated()), id: \.element.id) { index, item in
                if item.itemType != .trigger {
                    ZStack {
                        Image(item.type)
                            .resizable()
                            .frame(width: item.size, height: item.size)
                        
                        if !showTriggerPreview {
                            ZStack {
                                Circle()
                                    .fill(getItemColor(for: item.itemType))
                                    .frame(width: 16, height: 16)
                                Text("\(placedItems.prefix(index + 1).filter { $0.itemType == item.itemType }.count)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .offset(x: item.size/2 - 4, y: -item.size/2 + 4)
                        }
                    }
                    .position(x: item.x, y: item.y)
                }
            }
            
            if !showTriggerPreview {
                if selectedMode == .props {
                    Image(selectedProp)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .position(x: currentX, y: currentY)
                        .opacity(0.6)
                } else if selectedMode == .items {
                    Image(selectedGameItem)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .position(x: currentX, y: currentY)
                        .opacity(0.6)
                } else if selectedMode == .enemies {
                    Image(selectedEnemy)
                        .resizable()
                        .frame(width: selectedEnemy == "frogcolli" ? 40 : 32,
                               height: selectedEnemy == "frogcolli" ? 40 : 32)
                        .position(x: enemyX, y: enemyY)
                        .opacity(0.6)
                }
            }
            
            if showTriggerPreview {
                Rectangle()
                    .stroke(Color.purple.opacity(0.5), lineWidth: 3)
                    .frame(width: triggerWidth, height: triggerHeight)
                    .position(x: triggerX, y: triggerY)
            }
            
            ForEach(Array(placedItems.enumerated()), id: \.element.id) { index, item in
                if item.itemType == .trigger {
                    ZStack {
                        Rectangle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: item.width ?? 60, height: item.height ?? 30)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.purple, lineWidth: 1)
                            )
                        
                        ZStack {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 16, height: 16)
                            Text("\(placedItems.prefix(index + 1).filter { $0.itemType == .trigger }.count)")
                                .foregroundColor(.white)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .offset(x: (item.width ?? 60)/2 - 8, y: -(item.height ?? 30)/2 + 8)
                    }
                    .position(x: item.x, y: item.y)
                }
            }
            
            // Door numbers
            if doorTop {
                Text("\(level * 100 + doorTopLeadsTo)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    )
                    .position(x: 200, y: 20)
            }
            
            if doorRight {
                Text("\(level * 100 + doorRightLeadsTo)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    )
                    .position(x: 380, y: 120)
            }
            
            if doorDown {
                Text("\(level * 100 + doorDownLeadsTo)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    )
                    .position(x: 200, y: 220)
            }
            
            if doorLeft {
                Text("\(level * 100 + doorLeftLeadsTo)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    )
                    .position(x: 20, y: 120)
            }
        }
        .frame(width: 400, height: 240)
        .background(Color.white)
        .clipped()
    }
    
    private func getItemColor(for itemType: ItemType) -> Color {
        switch itemType {
        case .prop:
            return .green
        case .enemy:
            return .red
        case .item:
            return .purple
        case .trigger:
            return .purple
        }
    }
} 
