import SwiftUI

struct NodePreviewMapView: View {
    let placedItems: [PlacedItem]
    let doorTop: Bool
    let doorRight: Bool
    let doorDown: Bool
    let doorLeft: Bool
    let doorTopLeadsTo: Int
    let doorRightLeadsTo: Int
    let doorDownLeadsTo: Int
    let doorLeftLeadsTo: Int
    let level: Int
    
    var body: some View {
        ZStack {
            Image("room")
                .resizable()
                .frame(width: 400, height: 240)
            
            Rectangle()
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 400, height: 240)
            
            // Items y enemigos sin números
            ForEach(placedItems) { item in
                if item.itemType != .trigger {
                    Image(item.type)
                        .resizable()
                        .frame(width: item.size, height: item.size)
                        .position(x: item.x, y: item.y)
                }
            }
            
            // Triggers
            ForEach(placedItems) { item in
                if item.itemType == .trigger {
                    Rectangle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: item.width ?? 60, height: item.height ?? 30)
                        .overlay(
                            Rectangle()
                                .stroke(Color.purple, lineWidth: 1)
                        )
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
} 