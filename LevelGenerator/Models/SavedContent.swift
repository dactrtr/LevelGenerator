import Foundation

protocol LevelEditorState {
    var currentLevel: Int { get }
    var floorNumber: Int { get }
    var tile: Int { get }
    var light: Double { get }
    var shadow: Bool { get }
    var placedItems: [PlacedItem] { get }
    var doorTop: Bool { get }
    var doorRight: Bool { get }
    var doorDown: Bool { get }
    var doorLeft: Bool { get }
    var doorTopLeadsTo: Int { get }
    var doorRightLeadsTo: Int { get }
    var doorDownLeadsTo: Int { get }
    var doorLeftLeadsTo: Int { get }
}

struct SavedLevel: Codable, Identifiable {
    let id: UUID
    var name: String
    var level: Int
    var roomNumber: Int
    var tile: Int
    var light: Double
    var shadow: Bool
    var doors: SavedDoors
    var placedItems: [PlacedItem]
    
    struct SavedDoors: Codable {
        var top: Bool
        var right: Bool
        var down: Bool
        var left: Bool
        var topLeadsTo: Int
        var rightLeadsTo: Int
        var downLeadsTo: Int
        var leftLeadsTo: Int
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, level, roomNumber, tile, light, shadow, doors, placedItems
    }
    
    mutating func update(with editor: LevelEditorState) {
        level = editor.currentLevel
        roomNumber = editor.floorNumber
        tile = editor.tile
        light = editor.light
        shadow = editor.shadow
        placedItems = editor.placedItems
        doors = SavedDoors(
            top: editor.doorTop,
            right: editor.doorRight,
            down: editor.doorDown,
            left: editor.doorLeft,
            topLeadsTo: editor.doorTopLeadsTo,
            rightLeadsTo: editor.doorRightLeadsTo,
            downLeadsTo: editor.doorDownLeadsTo,
            leftLeadsTo: editor.doorLeftLeadsTo
        )
    }
}

struct SavedScript: Codable, Identifiable {
    let id: UUID
    var name: String
    var dialogs: [Dialog]
    
    struct Dialog: Codable {
        var image: String
        var text: String
        var key: String
    }
    
    mutating func update(with scriptView: ScriptView) {
        name = scriptView.scriptName
        dialogs = scriptView.scriptDialogs.map { dialog in
            Dialog(image: dialog.image, text: dialog.text, key: dialog.key)
        }
    }
} 