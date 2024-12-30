import Foundation
import SwiftUI

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

// Clase para manejar la persistencia
class ContentStore: ObservableObject {
    @Published var levels: [SavedLevel] = []
    @Published var scripts: [SavedScript] = []
    
    private let levelsKey = "savedLevels"
    private let scriptsKey = "savedScripts"
    
    init() {
        loadContent()
    }
    
    func loadContent() {
        if let levelsData = UserDefaults.standard.data(forKey: levelsKey),
           let decodedLevels = try? JSONDecoder().decode([SavedLevel].self, from: levelsData) {
            levels = decodedLevels
        }
        
        if let scriptsData = UserDefaults.standard.data(forKey: scriptsKey),
           let decodedScripts = try? JSONDecoder().decode([SavedScript].self, from: scriptsData) {
            scripts = decodedScripts
        }
    }
    
    func saveContent() {
        if let encodedLevels = try? JSONEncoder().encode(levels) {
            UserDefaults.standard.set(encodedLevels, forKey: levelsKey)
        }
        
        if let encodedScripts = try? JSONEncoder().encode(scripts) {
            UserDefaults.standard.set(encodedScripts, forKey: scriptsKey)
        }
    }
    
    func addLevel(_ level: SavedLevel) {
        levels.append(level)
        saveContent()
    }
    
    func updateLevel(at index: Int, with level: SavedLevel) {
        levels[index] = level
        saveContent()
    }
    
    func deleteLevel(at offsets: IndexSet) {
        levels.remove(atOffsets: offsets)
        saveContent()
    }
    
    func addScript(_ script: SavedScript) {
        scripts.append(script)
        saveContent()
    }
    
    func updateScript(at index: Int, with script: SavedScript) {
        scripts[index] = script
        saveContent()
    }
    
    func deleteScript(at offsets: IndexSet) {
        scripts.remove(atOffsets: offsets)
        saveContent()
    }
    
    // Estructura para exportar todo el contenido
    struct ExportData: Codable {
        let levels: [SavedLevel]
        let scripts: [SavedScript]
        let version: String
        
        init(levels: [SavedLevel], scripts: [SavedScript]) {
            self.levels = levels
            self.scripts = scripts
            self.version = "1.0"  // Movido al inicializador
        }
    }
    
    // Exportar a String JSON
    func exportToJSON() -> String? {
        let exportData = ExportData(levels: levels, scripts: scripts)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted  // Para mejor legibilidad
        if let jsonData = try? encoder.encode(exportData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
    
    // Importar desde String JSON
    func importFromJSON(_ jsonString: String) -> Bool {
        guard let jsonData = jsonString.data(using: .utf8),
              let importedData = try? JSONDecoder().decode(ExportData.self, from: jsonData) else {
            return false
        }
        
        levels = importedData.levels
        scripts = importedData.scripts
        saveContent()
        return true
    }
    
    // Importar y fusionar con el contenido existente
    func mergeFromJSON(_ jsonString: String) -> Bool {
        guard let jsonData = jsonString.data(using: .utf8),
              let importedData = try? JSONDecoder().decode(ExportData.self, from: jsonData) else {
            return false
        }
        
        // Agregar solo elementos nuevos basados en ID
        let existingLevelIds = Set(levels.map { $0.id })
        let newLevels = importedData.levels.filter { !existingLevelIds.contains($0.id) }
        levels.append(contentsOf: newLevels)
        
        let existingScriptIds = Set(scripts.map { $0.id })
        let newScripts = importedData.scripts.filter { !existingScriptIds.contains($0.id) }
        scripts.append(contentsOf: newScripts)
        
        saveContent()
        return true
    }
}

extension ContentStore {
    func levelBinding(at index: Int) -> Binding<SavedLevel> {
        Binding(
            get: { self.levels[index] },
            set: { self.updateLevel(at: index, with: $0) }
        )
    }
    
    func scriptBinding(at index: Int) -> Binding<SavedScript> {
        Binding(
            get: { self.scripts[index] },
            set: { self.updateScript(at: index, with: $0) }
        )
    }
} 