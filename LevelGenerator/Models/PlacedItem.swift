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
    
    public init(
        type: String,
        x: Double,
        y: Double,
        itemType: ItemType,
        nocollide: Bool = false,
        speed: Double? = nil,
        width: Double? = nil,
        height: Double? = nil,
        script: String? = nil
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
    }
    
    public var size: CGFloat {
        switch type {
        case "frogcolli":
            return 40
        default:
            return 32
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, x, y, itemType, nocollide, speed, width, height, script
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        itemType = try container.decode(ItemType.self, forKey: .itemType)
        nocollide = try container.decode(Bool.self, forKey: .nocollide)
        speed = try container.decodeIfPresent(Double.self, forKey: .speed)
        width = try container.decodeIfPresent(Double.self, forKey: .width)
        height = try container.decodeIfPresent(Double.self, forKey: .height)
        script = try container.decodeIfPresent(String.self, forKey: .script)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(itemType, forKey: .itemType)
        try container.encode(nocollide, forKey: .nocollide)
        try container.encodeIfPresent(speed, forKey: .speed)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(script, forKey: .script)
    }
}

public enum ItemType: Codable {
    case furniture
    case enemy
    case trigger
} 