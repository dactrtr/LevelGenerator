import SwiftUI

public struct PlacedItem: Identifiable {
    public let id = UUID()
    public let type: String
    public let x: Double
    public let y: Double
    public let itemType: ItemType
    public let nocollide: Bool
    public let speed: Double?
    // Nuevos campos para triggers
    public let width: Double?
    public let height: Double?
    public let script: Int?
    
    public init(
        type: String,
        x: Double,
        y: Double,
        itemType: ItemType,
        nocollide: Bool = false,
        speed: Double? = nil,
        width: Double? = nil,
        height: Double? = nil,
        script: Int? = nil
    ) {
        self.type = type
        self.x = x
        self.y = y
        self.itemType = itemType
        self.nocollide = itemType == .furniture ? nocollide : false
        self.speed = speed
        self.width = width
        self.height = height
        self.script = script
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
    case trigger
} 