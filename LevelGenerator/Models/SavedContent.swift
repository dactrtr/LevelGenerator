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
    var comic: Bool { get }
    var comicName: String { get }
    var comicEnter: Bool { get }
}

struct SavedLevel: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var level: Int
    var roomNumber: Int
    var tile: Int
    var light: Double
    var shadow: Bool
    var doors: SavedDoors
    var placedItems: [PlacedItem]
    var comic: Bool
    var comicName: String
    var comicEnter: Bool
  
    
    
    struct SavedDoors: Codable, Hashable {
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
        case id, name, level, roomNumber, tile, light, shadow, doors, placedItems, comic, comicName, comicEnter
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
        comic = editor.comic
        comicName = editor.comicName
        comicEnter = editor.comicEnter
    }
    
    // Implementación de Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SavedLevel, rhs: SavedLevel) -> Bool {
        lhs.id == rhs.id
    }
    
    
}

// MARK: - Variables del jugador disponibles para condiciones

struct PlayerVariable: Identifiable {
    let id = UUID()
    let label: String
    let path: String
    let type: String // "bool" o "number"

    static let all: [PlayerVariable] = [
        PlayerVariable(label: "Es tiny",          path: "isTiny",                     type: "bool"),
        PlayerVariable(label: "Tiene lámpara",    path: "items.hasLamp",              type: "bool"),
        PlayerVariable(label: "Tiene botas",      path: "items.hasBoots",             type: "bool"),
        PlayerVariable(label: "Tiene sopapa",     path: "items.hasPlunger",           type: "bool"),
        PlayerVariable(label: "Tiene radio",      path: "items.hasRadio",             type: "bool"),
        PlayerVariable(label: "Tiene reloj",      path: "items.hasDWatch",            type: "bool"),
        PlayerVariable(label: "Puede flash",      path: "skills.canFlash",            type: "bool"),
        PlayerVariable(label: "Puede dash",       path: "skills.canDash",             type: "bool"),
        PlayerVariable(label: "Puede plungerang", path: "skills.canPlungerang",       type: "bool"),
        PlayerVariable(label: "Puede bailar",     path: "skills.canDance",            type: "bool"),
        PlayerVariable(label: "HP",               path: "healthPoints",               type: "number"),
        PlayerVariable(label: "Sanity",           path: "sanity",                     type: "number"),
        PlayerVariable(label: "Batería",          path: "battery",                    type: "number"),
        PlayerVariable(label: "Crew capturados",  path: "CrewMemberData.amountTaken", type: "number"),
        PlayerVariable(label: "Story counter",    path: "storyCounter",               type: "number"),
    ]
}

// MARK: - Entrada de conditionalScripts

struct ConditionalScript: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var variablePath: String           // Path en PlayerData, ej: "isTiny", "items.hasLamp"
    var variableType: String           // "bool" o "number"
    var negate: Bool = false           // Solo para bool: agrega ! al frente
    var numericOperator: String = ">"  // Solo para number: ">", "<", ">=", "<=", "==", "!="
    var numericValue: Int = 0          // Solo para number
    var scriptName: String = ""        // Nombre del script a ejecutar si condición es verdadera
    var isTerminal: Bool = false       // Si true, agrega ! al final (destruye el trigger)

    // No es Codable — se calcula en runtime
    var conditionString: String {
        let condition: String
        if variableType == "bool" {
            condition = negate ? "!\(variablePath)" : variablePath
        } else {
            condition = "\(variablePath) \(numericOperator) \(numericValue)"
        }
        let suffix = isTerminal ? "!" : ""
        return "\(condition):\(scriptName)\(suffix)"
    }

    init(variablePath: String = "isTiny", variableType: String = "bool") {
        self.variablePath = variablePath
        self.variableType = variableType
    }
}

// MARK: - Script guardado

struct SavedScript: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var dialogs: [SavedDialog]
    var conditionalScripts: [ConditionalScript]

    struct SavedDialog: Codable, Hashable {
        var image: String
        var text: String
        var key: String
    }

    // Init para crear nuevos scripts
    init(id: UUID = UUID(), name: String, dialogs: [SavedDialog] = [], conditionalScripts: [ConditionalScript] = []) {
        self.id = id
        self.name = name
        self.dialogs = dialogs
        self.conditionalScripts = conditionalScripts
    }

    // Decoder con compatibilidad hacia atrás (scripts sin conditionalScripts)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        dialogs = try container.decode([SavedDialog].self, forKey: .dialogs)
        conditionalScripts = (try? container.decodeIfPresent([ConditionalScript].self, forKey: .conditionalScripts)) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case id, name, dialogs, conditionalScripts
    }

    mutating func update(with scriptView: ScriptView) {
        name = scriptView.scriptName
        dialogs = scriptView.scriptDialogs.map { dialog in
            SavedDialog(image: dialog.image, text: dialog.text, key: dialog.key)
        }
        conditionalScripts = scriptView.scriptConditionalScripts
    }

    // Implementación de Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SavedScript, rhs: SavedScript) -> Bool {
        lhs.id == rhs.id
    }
}

// Estructura para mantener la información del trigger y su ubicación
public struct TriggerScriptInfo: Identifiable {
    public let id = UUID()
    public let name: String
    public let level: Int
    public let room: Int
    public let roomName: String
    
    public var locationDescription: String {
        "Level \(level) - Room \(room) (\(roomName))"
    }
}

// Estructura para agrupar scripts por habitación
public struct RoomScripts: Identifiable {
    public let id = UUID()
    public let level: Int
    public let room: Int
    public let roomName: String
    public let scripts: [TriggerScriptInfo]
    
    public var title: String {
        "Level \(level) - Room \(room) (\(roomName))"
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
        let nodeStyles: [NodeStyle]
        let version: String
        
        init(levels: [SavedLevel], scripts: [SavedScript]) {
            self.levels = levels
            self.scripts = scripts
            self.nodeStyles = UserDefaults.standard.data(forKey: "nodeStyles")
                .flatMap { try? JSONDecoder().decode([NodeStyle].self, from: $0) } ?? []
            self.version = "1.0"
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
        if let encodedStyles = try? JSONEncoder().encode(importedData.nodeStyles) {
            UserDefaults.standard.set(encodedStyles, forKey: nodeStylesKey)
        }
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
        
        // Fusionar estilos de nodos
        let currentStyles = loadNodeStyles()
        let existingRoomNumbers = Set(currentStyles.map { $0.roomNumber })
        let newStyles = importedData.nodeStyles.filter { !existingRoomNumbers.contains($0.roomNumber) }
        if let encodedStyles = try? JSONEncoder().encode(currentStyles + newStyles) {
            UserDefaults.standard.set(encodedStyles, forKey: nodeStylesKey)
        }
        
        saveContent()
        return true
    }
    
    // Función actualizada para obtener scripts agrupados por habitación
    func getTriggerScripts() -> [RoomScripts] {
        var scriptsByRoom: [String: [TriggerScriptInfo]] = [:]
        
        for level in levels {
            let roomKey = "\(level.level)-\(level.roomNumber)"
            
            for item in level.placedItems {
                // Solo incluir triggers que no sean cutscenes
                if let scriptName = item.triggerScriptName, item.triggerType != "cutscene" {
                    let scriptInfo = TriggerScriptInfo(
                        name: scriptName,
                        level: level.level,
                        room: level.roomNumber,
                        roomName: level.name
                    )
                    
                    if scriptsByRoom[roomKey] == nil {
                        scriptsByRoom[roomKey] = []
                    }
                    scriptsByRoom[roomKey]?.append(scriptInfo)
                }
            }
        }
        
        // Filtrar scripts que ya existen
        let existingScriptNames = Set(scripts.map { $0.name })
        
        // Convertir el diccionario a un array de RoomScripts
        return scriptsByRoom.compactMap { key, scripts in
            let filteredScripts = scripts.filter { !existingScriptNames.contains($0.name) }
            guard !filteredScripts.isEmpty,
                  let firstScript = filteredScripts.first else { return nil }
            
            return RoomScripts(
                level: firstScript.level,
                room: firstScript.room,
                roomName: firstScript.roomName,
                scripts: filteredScripts.sorted { $0.name < $1.name }
            )
        }
        .sorted { $0.level == $1.level ? $0.room < $1.room : $0.level < $1.level }
    }
}

extension ContentStore {
    func levelBinding(at index: Int) -> Binding<SavedLevel> {
        let id = levels[index].id
        return Binding(
            get: {
                guard let i = self.levels.firstIndex(where: { $0.id == id }) else {
                    return self.levels[index < self.levels.count ? index : self.levels.count - 1]
                }
                return self.levels[i]
            },
            set: {
                if let i = self.levels.firstIndex(where: { $0.id == id }) {
                    self.updateLevel(at: i, with: $0)
                }
            }
        )
    }
    
    func scriptBinding(at index: Int) -> Binding<SavedScript> {
        let id = scripts[index].id
        return Binding(
            get: {
                guard let i = self.scripts.firstIndex(where: { $0.id == id }) else {
                    return self.scripts[index < self.scripts.count ? index : self.scripts.count - 1]
                }
                return self.scripts[i]
            },
            set: {
                if let i = self.scripts.firstIndex(where: { $0.id == id }) {
                    self.updateScript(at: i, with: $0)
                }
            }
        )
    }
}

extension ContentStore {
    struct NodePosition: Codable {
        let roomNumber: Int
        let x: Double
        let y: Double
    }
    
    private var nodePositionsKey: String { "nodePositions" }
    
    func saveNodePositions(_ positions: [NodePosition]) {
        if let encoded = try? JSONEncoder().encode(positions) {
            UserDefaults.standard.set(encoded, forKey: nodePositionsKey)
        }
    }
    
    func loadNodePositions() -> [NodePosition] {
        guard let data = UserDefaults.standard.data(forKey: nodePositionsKey),
              let positions = try? JSONDecoder().decode([NodePosition].self, from: data) else {
            return []
        }
        return positions
    }
}

extension ContentStore {
    struct NodeStyle: Codable {
        let roomNumber: Int
        let borderColor: String  // Guardamos el color como string
    }
    
    private var nodeStylesKey: String { "nodeStyles" }
    
    func saveNodeStyles(_ nodes: [RoomNode]) {
        let styles = nodes.map { node in
            NodeStyle(
                roomNumber: node.room,
                borderColor: colorToString(node.borderColor)
            )
        }
        if let encoded = try? JSONEncoder().encode(styles) {
            UserDefaults.standard.set(encoded, forKey: nodeStylesKey)
        }
    }
    
    func loadNodeStyles() -> [NodeStyle] {
        guard let data = UserDefaults.standard.data(forKey: nodeStylesKey),
              let styles = try? JSONDecoder().decode([NodeStyle].self, from: data) else {
            return []
        }
        return styles
    }
    
    private func colorToString(_ color: Color) -> String {
        switch color {
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green"
        default: return "clear"
        }
    }
} 
