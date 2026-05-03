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

    struct SavedDialog: Codable, Hashable {
        var video: String
        var text: String
        var key: String
        var screen: String?
    }

    init(id: UUID = UUID(), name: String, dialogs: [SavedDialog] = []) {
        self.id = id
        self.name = name
        self.dialogs = dialogs
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SavedScript, rhs: SavedScript) -> Bool { lhs.id == rhs.id }
}

// MARK: - Trigger guardado

struct SavedTrigger: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var triggerType: String?
    var fallbackScript: String?
    var conditionalScripts: [ConditionalScript]

    init(id: UUID = UUID(), name: String,
         triggerType: String? = nil,
         fallbackScript: String? = nil,
         conditionalScripts: [ConditionalScript] = []) {
        self.id = id
        self.name = name
        self.triggerType = triggerType
        self.fallbackScript = fallbackScript
        self.conditionalScripts = conditionalScripts
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SavedTrigger, rhs: SavedTrigger) -> Bool { lhs.id == rhs.id }
}

struct SavedNPC: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var conditionalScripts: [ConditionalScript]

    init(id: UUID = UUID(), name: String, conditionalScripts: [ConditionalScript] = []) {
        self.id = id
        self.name = name
        self.conditionalScripts = conditionalScripts
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SavedNPC, rhs: SavedNPC) -> Bool { lhs.id == rhs.id }
}

// Clase para manejar la persistencia
class ContentStore: ObservableObject {
    @Published var levels: [SavedLevel] = []
    @Published var scripts: [SavedScript] = []
    @Published var triggers: [SavedTrigger] = []
    @Published var npcs: [SavedNPC] = []

    private let levelsKey = "savedLevels"
    private let scriptsKey = "savedScripts"
    private let triggersKey = "savedTriggers"
    private let npcsKey = "savedNPCs"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadContent()
    }

    func loadContent() {
        if let data = defaults.data(forKey: levelsKey),
           let decoded = try? JSONDecoder().decode([SavedLevel].self, from: data) {
            levels = decoded
        }
        if let data = defaults.data(forKey: scriptsKey),
           let decoded = try? JSONDecoder().decode([SavedScript].self, from: data) {
            scripts = decoded
        }
        if let data = defaults.data(forKey: triggersKey),
           let decoded = try? JSONDecoder().decode([SavedTrigger].self, from: data) {
            triggers = decoded
        }
        if let data = defaults.data(forKey: npcsKey),
           let decoded = try? JSONDecoder().decode([SavedNPC].self, from: data) {
            npcs = decoded
        }
    }

    func saveContent() {
        if let encoded = try? JSONEncoder().encode(levels) { defaults.set(encoded, forKey: levelsKey) }
        if let encoded = try? JSONEncoder().encode(scripts) { defaults.set(encoded, forKey: scriptsKey) }
        if let encoded = try? JSONEncoder().encode(triggers) { defaults.set(encoded, forKey: triggersKey) }
        if let encoded = try? JSONEncoder().encode(npcs) { defaults.set(encoded, forKey: npcsKey) }
    }

    // MARK: Levels
    func addLevel(_ level: SavedLevel) { levels.append(level); saveContent() }
    private func updateLevel(at index: Int, with level: SavedLevel) { levels[index] = level; saveContent() }
    func deleteLevel(at offsets: IndexSet) { levels.remove(atOffsets: offsets); saveContent() }

    // MARK: Scripts
    func addScript(_ script: SavedScript) { scripts.append(script); saveContent() }
    private func updateScript(at index: Int, with script: SavedScript) { scripts[index] = script; saveContent() }
    func deleteScript(at offsets: IndexSet) { scripts.remove(atOffsets: offsets); saveContent() }

    // MARK: Triggers
    func addTrigger(_ trigger: SavedTrigger) { triggers.append(trigger); saveContent() }
    private func updateTrigger(at index: Int, with trigger: SavedTrigger) { triggers[index] = trigger; saveContent() }
    func deleteTrigger(at offsets: IndexSet) { triggers.remove(atOffsets: offsets); saveContent() }

    // MARK: NPCs
    func addNPC(_ npc: SavedNPC) { npcs.append(npc); saveContent() }
    private func updateNPC(at index: Int, with npc: SavedNPC) { npcs[index] = npc; saveContent() }
    func deleteNPC(at offsets: IndexSet) { npcs.remove(atOffsets: offsets); saveContent() }

    // MARK: Export / Import
    struct ExportData: Codable {
        let levels: [SavedLevel]
        let scripts: [SavedScript]
        let triggers: [SavedTrigger]
        let npcs: [SavedNPC]
        let nodeStyles: [NodeStyle]
        let version: String

        init(levels: [SavedLevel], scripts: [SavedScript], triggers: [SavedTrigger], npcs: [SavedNPC], defaults: UserDefaults = .standard) {
            self.levels = levels
            self.scripts = scripts
            self.triggers = triggers
            self.npcs = npcs
            self.nodeStyles = defaults.data(forKey: "nodeStyles")
                .flatMap { try? JSONDecoder().decode([NodeStyle].self, from: $0) } ?? []
            self.version = "2.0"
        }
    }

    func exportToJSON() -> String? {
        let data = ExportData(levels: levels, scripts: scripts, triggers: triggers, npcs: npcs, defaults: defaults)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let jsonData = try? encoder.encode(data),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return nil }
        return jsonString
    }

    func importFromJSON(_ jsonString: String) -> Bool {
        guard let jsonData = jsonString.data(using: .utf8),
              let imported = try? JSONDecoder().decode(ExportData.self, from: jsonData) else { return false }
        levels = imported.levels
        scripts = imported.scripts
        triggers = imported.triggers
        npcs = imported.npcs
        if let encoded = try? JSONEncoder().encode(imported.nodeStyles) {
            defaults.set(encoded, forKey: nodeStylesKey)
        }
        saveContent()
        return true
    }

    func mergeFromJSON(_ jsonString: String) -> Bool {
        guard let jsonData = jsonString.data(using: .utf8),
              let imported = try? JSONDecoder().decode(ExportData.self, from: jsonData) else { return false }

        let existingLevelIds = Set(levels.map { $0.id })
        levels.append(contentsOf: imported.levels.filter { !existingLevelIds.contains($0.id) })

        let existingScriptIds = Set(scripts.map { $0.id })
        scripts.append(contentsOf: imported.scripts.filter { !existingScriptIds.contains($0.id) })

        let existingTriggerIds = Set(triggers.map { $0.id })
        triggers.append(contentsOf: imported.triggers.filter { !existingTriggerIds.contains($0.id) })

        let existingNPCIds = Set(npcs.map { $0.id })
        npcs.append(contentsOf: imported.npcs.filter { !existingNPCIds.contains($0.id) })

        let currentStyles = loadNodeStyles()
        let existingRooms = Set(currentStyles.map { $0.roomNumber })
        let newStyles = imported.nodeStyles.filter { !existingRooms.contains($0.roomNumber) }
        if let encoded = try? JSONEncoder().encode(currentStyles + newStyles) {
            defaults.set(encoded, forKey: nodeStylesKey)
        }
        saveContent()
        return true
    }
}

extension ContentStore {
    func levelBinding(id: UUID) -> Binding<SavedLevel> {
        Binding(
            get: {
                guard let i = self.levels.firstIndex(where: { $0.id == id }) else {
                    return SavedLevel(
                        id: id, name: "", level: 0, roomNumber: 0, tile: 0,
                        light: 1.0, shadow: false,
                        doors: .init(top: false, right: false, down: false, left: false,
                                     topLeadsTo: 0, rightLeadsTo: 0, downLeadsTo: 0, leftLeadsTo: 0),
                        placedItems: [], comic: false, comicName: "", comicEnter: false
                    )
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

    func scriptBinding(id: UUID) -> Binding<SavedScript> {
        Binding(
            get: {
                guard let i = self.scripts.firstIndex(where: { $0.id == id }) else {
                    return SavedScript(id: id, name: "")
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

    func triggerBinding(id: UUID) -> Binding<SavedTrigger> {
        Binding(
            get: {
                guard let i = self.triggers.firstIndex(where: { $0.id == id }) else {
                    return SavedTrigger(id: id, name: "")
                }
                return self.triggers[i]
            },
            set: {
                if let i = self.triggers.firstIndex(where: { $0.id == id }) {
                    self.updateTrigger(at: i, with: $0)
                }
            }
        )
    }

    func npcBinding(id: UUID) -> Binding<SavedNPC> {
        Binding(
            get: {
                guard let i = self.npcs.firstIndex(where: { $0.id == id }) else {
                    return SavedNPC(id: id, name: "")
                }
                return self.npcs[i]
            },
            set: {
                if let i = self.npcs.firstIndex(where: { $0.id == id }) {
                    self.updateNPC(at: i, with: $0)
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
