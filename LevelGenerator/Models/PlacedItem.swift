import SwiftUI

public struct PlacedItem: Identifiable {
    public let id = UUID()
    public let type: String
    public let x: Double
    public let y: Double
    public let itemType: ItemType
    public let nocollide: Bool
    public let speed: Double?  // Opcional porque solo los enemigos lo usan
    
    public init(
        type: String,
        x: Double,
        y: Double,
        itemType: ItemType,
        nocollide: Bool = false,
        speed: Double? = nil
    ) {
        self.type = type
        self.x = x
        self.y = y
        self.itemType = itemType
        self.nocollide = nocollide
        self.speed = speed
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