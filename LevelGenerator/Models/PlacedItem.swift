import SwiftUI

public struct PlacedItem: Identifiable {
    public let id = UUID()
    public let type: String
    public let x: Double
    public let y: Double
    public let itemType: ItemType
    
    public init(type: String, x: Double, y: Double, itemType: ItemType) {
        self.type = type
        self.x = x
        self.y = y
        self.itemType = itemType
    }
    
    public var size: CGFloat {
        switch type {
        case "frogcolli":
            return 40
        default:
            return 32
        }
    }
}

public enum ItemType {
    case furniture
    case enemy
} 