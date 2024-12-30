import SwiftUI

public struct PlacedItem: Codable, Identifiable {
    public let id: UUID
    public let type: String
    public let x: Double
    public let y: Double
    public let itemType: ItemType
    public let nocollide: Bool
    public let speed: Double?
    public let width: Double?
    public let height: Double?
    public let script: String?
    public let triggerType: String?
    
    public init(
        type: String,
        x: Double,
        y: Double,
        itemType: ItemType,
        nocollide: Bool = false,
        speed: Double? = nil,
        width: Double? = nil,
        height: Double? = nil,
        script: String? = nil,
        triggerType: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.x = x
        self.y = y
        self.itemType = itemType
        self.nocollide = itemType == .furniture ? nocollide : false
        self.speed = speed
        self.width = width
        self.height = height
        self.script = script
        self.triggerType = triggerType
    }
    
    public var size: CGFloat {
        switch type {
        case "frogcolli":
            return 40
        default:
            return 32
        }
    }
    
    // Función auxiliar para obtener el nombre del script si es un trigger
    var triggerScriptName: String? {
        if itemType == .trigger {
            return script
        }
        return nil
    }
}

public enum ItemType: Codable {
    case furniture
    case enemy
    case trigger
} 