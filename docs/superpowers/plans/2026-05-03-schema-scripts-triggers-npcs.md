# Scripts / Triggers / NPCs Schema Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor LevelGenerator so Scripts are a standalone global pool, Triggers reference scripts by name, and NPCs are a new named-group entity with conditionalScripts.

**Architecture:** Three independent top-level models (`SavedScript`, `SavedTrigger`, `SavedNPC`) each with its own CRUD in `ContentStore`. Sidebar gains Scripts and NPCs sections. Triggers lose their embedded scripts array and gain `triggerType` + `fallbackScript` fields.

**Tech Stack:** Swift, SwiftUI, UserDefaults persistence, Swift Testing framework (`@Test` / `#expect`)

---

## File Map

| Action | File |
|--------|------|
| Modify | `LevelGenerator/Models/SavedContent.swift` |
| Modify | `LevelGenerator/Models/SidebarItem.swift` |
| Modify | `LevelGenerator/Models/ScriptLuaGenerator.swift` |
| Modify | `LevelGenerator/Views/ScriptView.swift` |
| Modify | `LevelGenerator/Views/DialogRow.swift` |
| Modify | `LevelGenerator/Views/macOS/MacContentView.swift` |
| Modify | `LevelGenerator/Views/Main/ContentListView.swift` |
| Rewrite | `LevelGenerator/Views/Sheets/NewScriptInTriggerSheet.swift` → becomes `NewScriptSheet.swift` (same file, new struct name) |
| Create | `LevelGenerator/Views/TriggerDetailView.swift` |
| Create | `LevelGenerator/Views/NPCDetailView.swift` |
| Create | `LevelGenerator/Views/Sheets/NewNPCSheet.swift` |
| Delete | `LevelGenerator/Views/Main/TriggerScriptsView.swift` |
| Rewrite | `LevelGeneratorTests/ContentStoreTriggerTests.swift` |
| Modify | `LevelGeneratorTests/ScriptLuaGeneratorTests.swift` |

---

## Task 1: Restructure data models in SavedContent.swift

**Files:**
- Modify: `LevelGenerator/Models/SavedContent.swift`

- [ ] **Step 1: Replace `SavedScript` struct**

Replace the existing `SavedScript` struct (lines 148–180) with:

```swift
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
```

- [ ] **Step 2: Replace `SavedTrigger` struct**

Replace the existing `SavedTrigger` struct (lines 184–201) with:

```swift
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
```

- [ ] **Step 3: Add `SavedNPC` struct** immediately after `SavedTrigger`:

```swift
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
```

- [ ] **Step 4: Replace `ContentStore` class**

Replace the entire `ContentStore` class (everything from `class ContentStore` through the closing `}` of `importFromJSON`/`mergeFromJSON`) with:

```swift
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
    func updateLevel(at index: Int, with level: SavedLevel) { levels[index] = level; saveContent() }
    func deleteLevel(at offsets: IndexSet) { levels.remove(atOffsets: offsets); saveContent() }

    // MARK: Scripts
    func addScript(_ script: SavedScript) { scripts.append(script); saveContent() }
    func updateScript(at index: Int, with script: SavedScript) { scripts[index] = script; saveContent() }
    func deleteScript(at offsets: IndexSet) { scripts.remove(atOffsets: offsets); saveContent() }

    // MARK: Triggers
    func addTrigger(_ trigger: SavedTrigger) { triggers.append(trigger); saveContent() }
    func updateTrigger(at index: Int, with trigger: SavedTrigger) { triggers[index] = trigger; saveContent() }
    func deleteTrigger(at offsets: IndexSet) { triggers.remove(atOffsets: offsets); saveContent() }

    // MARK: NPCs
    func addNPC(_ npc: SavedNPC) { npcs.append(npc); saveContent() }
    func updateNPC(at index: Int, with npc: SavedNPC) { npcs[index] = npc; saveContent() }
    func deleteNPC(at offsets: IndexSet) { npcs.remove(atOffsets: offsets); saveContent() }

    // MARK: Export / Import
    struct ExportData: Codable {
        let levels: [SavedLevel]
        let scripts: [SavedScript]
        let triggers: [SavedTrigger]
        let npcs: [SavedNPC]
        let nodeStyles: [NodeStyle]
        let version: String

        init(levels: [SavedLevel], scripts: [SavedScript], triggers: [SavedTrigger], npcs: [SavedNPC]) {
            self.levels = levels
            self.scripts = scripts
            self.triggers = triggers
            self.npcs = npcs
            self.nodeStyles = UserDefaults.standard.data(forKey: "nodeStyles")
                .flatMap { try? JSONDecoder().decode([NodeStyle].self, from: $0) } ?? []
            self.version = "2.0"
        }
    }

    func exportToJSON() -> String? {
        let data = ExportData(levels: levels, scripts: scripts, triggers: triggers, npcs: npcs)
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
            UserDefaults.standard.set(encoded, forKey: nodeStylesKey)
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
            UserDefaults.standard.set(encoded, forKey: nodeStylesKey)
        }
        saveContent()
        return true
    }
}
```

- [ ] **Step 5: Replace the three `ContentStore` binding extensions**

Replace the extension that contains `levelBinding`, `triggerBinding`, and `scriptBinding(triggerId:scriptId:)` with:

```swift
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
```

- [ ] **Step 6: Build to verify compilation**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD"
```

Expected: errors in test files and views that reference old API (e.g. `trigger.scripts`, `SavedDialog(image:)`). The model itself should compile. Fix any errors in `SavedContent.swift` itself before proceeding.

- [ ] **Step 7: Commit**

```bash
git add LevelGenerator/Models/SavedContent.swift
git commit -m "feat: restructure data models — standalone scripts, SavedNPC, new ContentStore CRUD"
```

---

## Task 2: Update SidebarItem

**Files:**
- Modify: `LevelGenerator/Models/SidebarItem.swift`

- [ ] **Step 1: Replace file contents**

```swift
import Foundation

enum SidebarItem: Hashable {
    case levels
    case script(UUID)
    case trigger(UUID)
    case npc(UUID)
}
```

- [ ] **Step 2: Commit**

```bash
git add LevelGenerator/Models/SidebarItem.swift
git commit -m "feat: add .script and .npc cases to SidebarItem"
```

---

## Task 3: Update ScriptLuaGenerator + tests

**Files:**
- Modify: `LevelGenerator/Models/ScriptLuaGenerator.swift`
- Modify: `LevelGeneratorTests/ScriptLuaGeneratorTests.swift`

- [ ] **Step 1: Update existing tests to use `video:` field name and add new failing tests**

Replace the full contents of `LevelGeneratorTests/ScriptLuaGeneratorTests.swift` with:

```swift
import Testing
@testable import LevelGenerator

struct ScriptLuaGeneratorTests {

    @Test func lua_containsNameAndDialogKey() {
        let script = SavedScript(name: "big", dialogs: [
            SavedScript.SavedDialog(video: "player", text: "Hello", key: "big-01")
        ])
        let result = ScriptLuaGenerator.lua(for: script)
        #expect(result.contains("name = \"big\""))
        #expect(result.contains("text = \"big-01\""))
        #expect(result.contains("video = 'player'"))
    }

    @Test func lua_emptyDialogs_stillContainsName() {
        let script = SavedScript(name: "empty")
        let result = ScriptLuaGenerator.lua(for: script)
        #expect(result.contains("name = \"empty\""))
    }

    @Test func localization_formatsKeyValuePair() {
        let script = SavedScript(name: "big", dialogs: [
            SavedScript.SavedDialog(video: "player", text: "Hello world", key: "big-01")
        ])
        let result = ScriptLuaGenerator.localization(for: script)
        #expect(result == "\"big-01\" = \"Hello world\"")
    }

    @Test func localization_multipleDialogs_joinedWithDoubleNewline() {
        let script = SavedScript(name: "big", dialogs: [
            SavedScript.SavedDialog(video: "player", text: "Line 1", key: "big-01"),
            SavedScript.SavedDialog(video: "player", text: "Line 2", key: "big-02")
        ])
        let result = ScriptLuaGenerator.localization(for: script)
        #expect(result.contains("\"big-01\" = \"Line 1\""))
        #expect(result.contains("\"big-02\" = \"Line 2\""))
        #expect(result.contains("\n\n"))
    }

    @Test func localization_emptyDialogs_returnsEmptyString() {
        let script = SavedScript(name: "empty")
        let result = ScriptLuaGenerator.localization(for: script)
        #expect(result.isEmpty)
    }

    @Test func triggerLua_containsIidAndType() {
        let trigger = SavedTrigger(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                                    name: "lamp-trigger",
                                    triggerType: "Search",
                                    fallbackScript: "lamp-dialog")
        let result = ScriptLuaGenerator.lua(for: trigger)
        #expect(result.contains("iid = \"00000000-0000-0000-0000-000000000001\""))
        #expect(result.contains("type = \"Search\""))
        #expect(result.contains("script = \"lamp-dialog\""))
    }

    @Test func triggerLua_nilType_omitsTypeField() {
        let trigger = SavedTrigger(id: UUID(), name: "t", triggerType: nil, fallbackScript: nil)
        let result = ScriptLuaGenerator.lua(for: trigger)
        #expect(!result.contains("type ="))
        #expect(!result.contains("script ="))
    }

    @Test func triggerLua_withConditionals_includesConditionStrings() {
        var condition = ConditionalScript(variablePath: "isTiny", variableType: "bool")
        condition.scriptName = "tiny-dialog"
        condition.isTerminal = true
        let trigger = SavedTrigger(id: UUID(), name: "t", conditionalScripts: [condition])
        let result = ScriptLuaGenerator.lua(for: trigger)
        #expect(result.contains("\"isTiny:tiny-dialog!\""))
    }

    @Test func npcLua_containsIidAndConditionals() {
        var condition = ConditionalScript(variablePath: "true", variableType: "bool")
        condition.scriptName = "hello"
        let npc = SavedNPC(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                            name: "cat",
                            conditionalScripts: [condition])
        let result = ScriptLuaGenerator.lua(for: npc)
        #expect(result.contains("iid = \"00000000-0000-0000-0000-000000000002\""))
        #expect(result.contains("\"true:hello\""))
    }
}
```

- [ ] **Step 2: Run tests — expect failures on new trigger/NPC tests**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "Test.*passed|Test.*failed|error:"
```

Expected: `triggerLua_*` and `npcLua_*` tests fail with "value of type 'ScriptLuaGenerator' has no member 'lua'".

- [ ] **Step 3: Replace ScriptLuaGenerator.swift contents**

```swift
import Foundation

enum ScriptLuaGenerator {

    static func lua(for script: SavedScript) -> String {
        """
        {
            name = "\(script.name)",
            dialog = {
                \(script.dialogs.map { dialog in
                    """
                    {
                        video = '\(dialog.video)',
                        text = "\(dialog.key)",
                    }
                    """
                }.joined(separator: ",\n                "))

            }
        },
        """
    }

    static func lua(for trigger: SavedTrigger) -> String {
        var lines: [String] = ["    iid = \"\(trigger.id.uuidString)\","]
        if let type = trigger.triggerType {
            lines.append("    type = \"\(type)\",")
        }
        if let fallback = trigger.fallbackScript, !fallback.isEmpty {
            lines.append("    script = \"\(fallback)\",")
        }
        let condLines = trigger.conditionalScripts
            .map { "        \"\($0.conditionString)\"" }
            .joined(separator: ",\n")
        lines.append("    conditionalScripts = {")
        if !condLines.isEmpty { lines.append(condLines) }
        lines.append("    }")
        return "{\n" + lines.joined(separator: "\n") + "\n},"
    }

    static func lua(for npc: SavedNPC) -> String {
        let condLines = npc.conditionalScripts
            .map { "        \"\($0.conditionString)\"" }
            .joined(separator: ",\n")
        return """
        {
            iid = "\(npc.id.uuidString)",
            conditionalScripts = {
        \(condLines)
            }
        },
        """
    }

    static func localization(for script: SavedScript) -> String {
        script.dialogs.map { dialog in
            "\"\(dialog.key)\" = \"\(dialog.text)\""
        }.joined(separator: "\n\n")
    }
}
```

- [ ] **Step 4: Run tests — expect all to pass**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "Test.*passed|Test.*failed|error:"
```

Expected: All `ScriptLuaGeneratorTests` pass. Other test files may still fail (fixed in later tasks).

- [ ] **Step 5: Commit**

```bash
git add LevelGenerator/Models/ScriptLuaGenerator.swift LevelGeneratorTests/ScriptLuaGeneratorTests.swift
git commit -m "feat: update ScriptLuaGenerator — video field, add lua(for trigger:) and lua(for npc:)"
```

---

## Task 4: Rewrite ContentStore tests

**Files:**
- Rewrite: `LevelGeneratorTests/ContentStoreTriggerTests.swift`

- [ ] **Step 1: Replace file contents**

```swift
import Testing
import Foundation
import SwiftUI
@testable import LevelGenerator

struct ContentStoreTests {

    private func freshStore() -> ContentStore {
        let suiteName = "test-\(UUID().uuidString)"
        return ContentStore(defaults: UserDefaults(suiteName: suiteName)!)
    }

    // MARK: Scripts

    @Test func addScript_appendsScript() {
        let store = freshStore()
        store.addScript(SavedScript(name: "hello"))
        #expect(store.scripts.count == 1)
        #expect(store.scripts[0].name == "hello")
    }

    @Test func deleteScript_removesScript() {
        let store = freshStore()
        store.addScript(SavedScript(name: "hello"))
        store.deleteScript(at: IndexSet([0]))
        #expect(store.scripts.isEmpty)
    }

    @Test func scriptBinding_returnsCorrectScript() {
        let store = freshStore()
        store.addScript(SavedScript(name: "hello"))
        let id = store.scripts[0].id
        let binding = store.scriptBinding(id: id)
        #expect(binding.wrappedValue.name == "hello")
    }

    // MARK: Triggers

    @Test func addTrigger_appendsTrigger() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp"))
        #expect(store.triggers.count == 1)
        #expect(store.triggers[0].name == "lamp")
    }

    @Test func addTrigger_withTypeAndFallback_storesFields() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp", triggerType: "Search", fallbackScript: "lamp-dialog"))
        #expect(store.triggers[0].triggerType == "Search")
        #expect(store.triggers[0].fallbackScript == "lamp-dialog")
    }

    @Test func deleteTrigger_removesTrigger() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp"))
        store.deleteTrigger(at: IndexSet([0]))
        #expect(store.triggers.isEmpty)
    }

    @Test func triggerBinding_returnsCorrectTrigger() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp"))
        let id = store.triggers[0].id
        let binding = store.triggerBinding(id: id)
        #expect(binding.wrappedValue.name == "lamp")
    }

    // MARK: NPCs

    @Test func addNPC_appendsNPC() {
        let store = freshStore()
        store.addNPC(SavedNPC(name: "cat"))
        #expect(store.npcs.count == 1)
        #expect(store.npcs[0].name == "cat")
    }

    @Test func deleteNPC_removesNPC() {
        let store = freshStore()
        store.addNPC(SavedNPC(name: "cat"))
        store.deleteNPC(at: IndexSet([0]))
        #expect(store.npcs.isEmpty)
    }

    @Test func npcBinding_returnsCorrectNPC() {
        let store = freshStore()
        store.addNPC(SavedNPC(name: "cat"))
        let id = store.npcs[0].id
        let binding = store.npcBinding(id: id)
        #expect(binding.wrappedValue.name == "cat")
    }

    // MARK: Export / Import round-trip

    @Test func exportImportRoundTrip_preservesAllEntities() {
        let store = freshStore()
        store.addScript(SavedScript(name: "hello"))
        store.addTrigger(SavedTrigger(name: "lamp", triggerType: "Search"))
        store.addNPC(SavedNPC(name: "cat"))

        guard let json = store.exportToJSON() else {
            Issue.record("exportToJSON returned nil")
            return
        }

        let store2 = freshStore()
        let success = store2.importFromJSON(json)
        #expect(success)
        #expect(store2.scripts.count == 1)
        #expect(store2.triggers.count == 1)
        #expect(store2.npcs.count == 1)
        #expect(store2.scripts[0].name == "hello")
        #expect(store2.triggers[0].triggerType == "Search")
        #expect(store2.npcs[0].name == "cat")
    }
}
```

- [ ] **Step 2: Run tests**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "Test.*passed|Test.*failed|error:"
```

Expected: All `ContentStoreTests` pass. View-layer compile errors remain; ignore them for now.

- [ ] **Step 3: Commit**

```bash
git add LevelGeneratorTests/ContentStoreTriggerTests.swift
git commit -m "test: rewrite ContentStore tests for new flat scripts/triggers/npcs model"
```

---

## Task 5: Replace NewScriptInTriggerSheet with NewScriptSheet

**Files:**
- Rewrite: `LevelGenerator/Views/Sheets/NewScriptInTriggerSheet.swift`
- Create: `LevelGenerator/Views/Sheets/NewNPCSheet.swift`

- [ ] **Step 1: Replace contents of NewScriptInTriggerSheet.swift**

Rename the struct inside the file (keep the filename for now — Xcode doesn't require filename to match struct name):

```swift
import SwiftUI

struct NewScriptSheet: View {
    @ObservedObject var contentStore: ContentStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Script")
                .font(.headline)
            TextField("Script name (kebab-case)", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    contentStore.addScript(SavedScript(name: name))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
```

- [ ] **Step 2: Create NewNPCSheet.swift**

```swift
import SwiftUI

struct NewNPCSheet: View {
    @ObservedObject var contentStore: ContentStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New NPC")
                .font(.headline)
            TextField("NPC name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    contentStore.addNPC(SavedNPC(name: name))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add LevelGenerator/Views/Sheets/NewScriptInTriggerSheet.swift LevelGenerator/Views/Sheets/NewNPCSheet.swift
git commit -m "feat: replace NewScriptInTriggerSheet with NewScriptSheet, add NewNPCSheet"
```

---

## Task 6: Update DialogRow and ScriptView

**Files:**
- Modify: `LevelGenerator/Views/DialogRow.swift`
- Modify: `LevelGenerator/Views/ScriptView.swift`

- [ ] **Step 1: Update DialogRow.swift**

Replace the `image` parameter with `video`:

```swift
import SwiftUI

struct DialogRow: View {
    let video: String
    let text: String
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(video)
                .resizable()
                .frame(width: 118, height: 94)

            Text(text)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(PlatformColor.secondaryBackground)
        .cornerRadius(8)
    }
}
```

- [ ] **Step 2: Replace ScriptView.swift**

```swift
import SwiftUI

struct ScriptView: View {
    @Binding var script: SavedScript
    @Environment(\.dismiss) var dismiss

    @State private var selectedVideo: String = "player"
    @State private var currentDialog: String = ""
    @State private var currentScreen: String = ""
    @State private var currentName: String
    @State private var dialogs: [(video: String, text: String, key: String, screen: String?)]

    let availableVideos = [
        "player", "playerWorry", "playerSurprise", "playerHappy",
        "playerAngry", "playerSleepy", "playerScared", "playerCry",
        "radioHand", "radioPocket", "radioRing", "notesHand"
    ]

    init(script: Binding<SavedScript>) {
        self._script = script
        _currentName = State(initialValue: script.wrappedValue.name)
        _dialogs = State(initialValue: script.wrappedValue.dialogs.map {
            (video: $0.video, text: $0.text, key: $0.key, screen: $0.screen)
        })
    }

    private func generateScriptKey() -> String {
        let formattedName = currentName.lowercased().replacingOccurrences(of: " ", with: "-")
        let count = dialogs.filter { $0.key.starts(with: formattedName) }.count + 1
        return "\(formattedName)-\(String(format: "%02d", count))"
    }

    var generatedLuaScript: String {
        ScriptLuaGenerator.lua(for: currentSavedScript)
    }

    var generatedLocalization: String {
        ScriptLuaGenerator.localization(for: currentSavedScript)
    }

    private var currentSavedScript: SavedScript {
        SavedScript(
            name: currentName,
            dialogs: dialogs.map {
                SavedScript.SavedDialog(video: $0.video, text: $0.text, key: $0.key, screen: $0.screen.flatMap { $0.isEmpty ? nil : $0 })
            }
        )
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── Left Column: outputs ──────────────────────────────────────
            ScrollView {
                VStack(spacing: 12) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Generated Lua Script").font(.headline)
                                Spacer()
                                CopyButton(content: generatedLuaScript)
                            }
                            TextEditor(text: .constant(generatedLuaScript))
                                .font(.system(size: 9, design: .monospaced))
                                .frame(minHeight: 140)
                        }
                    }
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Generated Localization").font(.headline)
                                Spacer()
                                CopyButton(content: generatedLocalization)
                            }
                            TextEditor(text: .constant(generatedLocalization))
                                .font(.system(size: 9, design: .monospaced))
                                .frame(minHeight: 100)
                        }
                    }
                }
                .padding()
            }
            .frame(width: 400)

            // ── Center Column: dialogs ────────────────────────────────────
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(dialogs.enumerated()), id: \.offset) { index, dialog in
                            DialogRow(
                                video: dialog.video,
                                text: dialog.text,
                                onDelete: { dialogs.remove(at: index) }
                            )
                        }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .background(PlatformColor.background)

            // ── Right Column: input ───────────────────────────────────────
            VStack(spacing: 16) {
                GroupBox("Select Character") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.fixed(110))], spacing: 8) {
                            ForEach(availableVideos, id: \.self) { video in
                                Button { selectedVideo = video } label: {
                                    Image(video)
                                        .resizable()
                                        .frame(width: 118, height: 94)
                                        .padding(8)
                                        .background(selectedVideo == video ? Color.blue.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                GroupBox("Dialog Name") {
                    TextField("Enter dialog name", text: $currentName)
                        .textFieldStyle(.roundedBorder)
                }

                GroupBox("Dialog Text") {
                    TextEditor(text: Binding(
                        get: { currentDialog },
                        set: { if $0.count <= 94 { currentDialog = $0 } }
                    ))
                    .frame(height: 100)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(currentDialog.count)/94")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(4)
                            }
                        }
                    )
                }

                GroupBox("Screen (opcional)") {
                    TextField("Nombre de imagen", text: $currentScreen)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    guard !currentDialog.isEmpty && !currentName.isEmpty else { return }
                    dialogs.append((
                        video: selectedVideo,
                        text: currentDialog,
                        key: generateScriptKey(),
                        screen: currentScreen.isEmpty ? nil : currentScreen
                    ))
                    currentDialog = ""
                    currentScreen = ""
                } label: {
                    Text("Add Dialog").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentDialog.isEmpty || currentName.isEmpty)

                Spacer()
            }
            .frame(width: 300)
            .padding()
            .background(PlatformColor.groupedBackground)
        }
        .navigationTitle(script.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    script = currentSavedScript
                    dismiss()
                }
            }
        }
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD"
```

Expected: errors only in files not yet updated (MacContentView, ContentListView, TriggerScriptsView). `ScriptView.swift` and `DialogRow.swift` should compile.

- [ ] **Step 4: Commit**

```bash
git add LevelGenerator/Views/DialogRow.swift LevelGenerator/Views/ScriptView.swift
git commit -m "feat: update ScriptView and DialogRow — video field, screen optional, remove update(with:) coupling"
```

---

## Task 7: Create TriggerDetailView

**Files:**
- Create: `LevelGenerator/Views/TriggerDetailView.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI

struct TriggerDetailView: View {
    @Binding var trigger: SavedTrigger
    let availableScriptNames: [String]
    @State private var showConditionals = false

    private let triggerTypes = ["Story", "Cutscene", "Search", "Call", "Counter"]

    private var generatedLua: String {
        ScriptLuaGenerator.lua(for: trigger)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                GroupBox("Nombre") {
                    TextField("Nombre", text: $trigger.name)
                        .textFieldStyle(.roundedBorder)
                }

                GroupBox("Tipo") {
                    HStack(spacing: 8) {
                        Button("nil") { trigger.triggerType = nil }
                            .buttonStyle(trigger.triggerType == nil ? .borderedProminent : .bordered)
                        ForEach(triggerTypes, id: \.self) { type in
                            Button(type) { trigger.triggerType = type }
                                .buttonStyle(trigger.triggerType == type ? .borderedProminent : .bordered)
                        }
                    }
                }

                GroupBox("Fallback Script") {
                    if availableScriptNames.isEmpty {
                        TextField("Script name", text: Binding(
                            get: { trigger.fallbackScript ?? "" },
                            set: { trigger.fallbackScript = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    } else {
                        Menu(trigger.fallbackScript ?? "Sin fallback") {
                            Button("Sin fallback") { trigger.fallbackScript = nil }
                            ForEach(availableScriptNames, id: \.self) { name in
                                Button(name) { trigger.fallbackScript = name }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Button("Condicionales (\(trigger.conditionalScripts.count))") {
                    showConditionals = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Lua").font(.headline)
                            Spacer()
                            CopyButton(content: generatedLua)
                        }
                        TextEditor(text: .constant(generatedLua))
                            .font(.system(size: 9, design: .monospaced))
                            .frame(minHeight: 160)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showConditionals) {
            ConditionalScriptsEditorView(
                conditions: $trigger.conditionalScripts,
                availableScriptNames: availableScriptNames
            )
            .frame(minWidth: 800, minHeight: 500)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 3: Commit**

```bash
git add LevelGenerator/Views/TriggerDetailView.swift
git commit -m "feat: add TriggerDetailView — type picker, fallback script, conditionals, Lua output"
```

---

## Task 8: Create NPCDetailView

**Files:**
- Create: `LevelGenerator/Views/NPCDetailView.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI

struct NPCDetailView: View {
    @Binding var npc: SavedNPC
    let availableScriptNames: [String]
    @State private var showConditionals = false

    private var generatedLua: String {
        ScriptLuaGenerator.lua(for: npc)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                GroupBox("Nombre") {
                    TextField("Nombre", text: $npc.name)
                        .textFieldStyle(.roundedBorder)
                }

                Button("Condicionales (\(npc.conditionalScripts.count))") {
                    showConditionals = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Lua").font(.headline)
                            Spacer()
                            CopyButton(content: generatedLua)
                        }
                        TextEditor(text: .constant(generatedLua))
                            .font(.system(size: 9, design: .monospaced))
                            .frame(minHeight: 120)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showConditionals) {
            ConditionalScriptsEditorView(
                conditions: $npc.conditionalScripts,
                availableScriptNames: availableScriptNames
            )
            .frame(minWidth: 800, minHeight: 500)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 3: Commit**

```bash
git add LevelGenerator/Views/NPCDetailView.swift
git commit -m "feat: add NPCDetailView — name editor, conditionals, Lua output"
```

---

## Task 9: Update MacContentView

**Files:**
- Modify: `LevelGenerator/Views/macOS/MacContentView.swift`

- [ ] **Step 1: Replace MacContentView.swift contents**

```swift
#if os(macOS)
import SwiftUI

struct MacContentView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var importText: String
    @Binding var showingImportAlert: Bool
    @Binding var importAlertMessage: String

    @State private var selectedLevelId: UUID?
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var showingNewScriptSheet = false
    @State private var showingNewTriggerSheet = false
    @State private var showingNewNPCSheet = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // ── Sidebar ───────────────────────────────────────────────────
            List(selection: $selectedSidebarItem) {

                Section {
                    NavigationLink(value: SidebarItem.levels) {
                        Label("Levels", systemImage: "square.stack.3d.up")
                    }
                } header: {
                    HStack {
                        Text("Levels")
                        Spacer()
                        Button { showingNewLevelSheet = true } label: { Image(systemName: "plus") }
                            .buttonStyle(.plain)
                    }
                }

                Section {
                    ForEach(contentStore.scripts) { script in
                        NavigationLink(value: SidebarItem.script(script.id)) {
                            Text(script.name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                if let i = contentStore.scripts.firstIndex(where: { $0.id == script.id }) {
                                    contentStore.deleteScript(at: IndexSet([i]))
                                    selectedSidebarItem = .levels
                                }
                            } label: { Label("Delete Script", systemImage: "trash") }
                        }
                    }
                } header: {
                    HStack {
                        Text("Scripts")
                        Spacer()
                        Button { showingNewScriptSheet = true } label: { Image(systemName: "plus") }
                            .buttonStyle(.plain)
                    }
                }

                Section {
                    ForEach(contentStore.triggers) { trigger in
                        NavigationLink(value: SidebarItem.trigger(trigger.id)) {
                            Text(trigger.name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                if let i = contentStore.triggers.firstIndex(where: { $0.id == trigger.id }) {
                                    contentStore.deleteTrigger(at: IndexSet([i]))
                                    selectedSidebarItem = .levels
                                }
                            } label: { Label("Delete Trigger", systemImage: "trash") }
                        }
                    }
                } header: {
                    HStack {
                        Text("Triggers")
                        Spacer()
                        Button { showingNewTriggerSheet = true } label: { Image(systemName: "plus") }
                            .buttonStyle(.plain)
                    }
                }

                Section {
                    ForEach(contentStore.npcs) { npc in
                        NavigationLink(value: SidebarItem.npc(npc.id)) {
                            Text(npc.name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                if let i = contentStore.npcs.firstIndex(where: { $0.id == npc.id }) {
                                    contentStore.deleteNPC(at: IndexSet([i]))
                                    selectedSidebarItem = .levels
                                }
                            } label: { Label("Delete NPC", systemImage: "trash") }
                        }
                    }
                } header: {
                    HStack {
                        Text("NPCs")
                        Spacer()
                        Button { showingNewNPCSheet = true } label: { Image(systemName: "plus") }
                            .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Content")
            .listStyle(.sidebar)

        } content: {
            // ── Content column ────────────────────────────────────────────
            switch selectedSidebarItem {

            case .script(let scriptId)
                where contentStore.scripts.contains(where: { $0.id == scriptId }):
                ScriptView(script: contentStore.scriptBinding(id: scriptId))
                    .id(scriptId)
                    .toolbar {
                        exportImportMenu
                    }

            case .trigger(let triggerId)
                where contentStore.triggers.contains(where: { $0.id == triggerId }):
                TriggerDetailView(
                    trigger: contentStore.triggerBinding(id: triggerId),
                    availableScriptNames: contentStore.scripts.map { $0.name }
                )
                .id(triggerId)
                .navigationTitle(contentStore.triggers.first(where: { $0.id == triggerId })?.name ?? "")
                .toolbar { exportImportMenu }

            case .npc(let npcId)
                where contentStore.npcs.contains(where: { $0.id == npcId }):
                NPCDetailView(
                    npc: contentStore.npcBinding(id: npcId),
                    availableScriptNames: contentStore.scripts.map { $0.name }
                )
                .id(npcId)
                .navigationTitle(contentStore.npcs.first(where: { $0.id == npcId })?.name ?? "")
                .toolbar { exportImportMenu }

            default:
                List(selection: $selectedLevelId) {
                    ForEach(contentStore.levels) { level in
                        NavigationLink(value: level.id) {
                            LevelRow(level: level)
                        }
                    }
                    .onDelete { indexSet in
                        contentStore.deleteLevel(at: indexSet)
                        selectedLevelId = nil
                    }
                }
                .navigationTitle("Levels")
                .toolbar { exportImportMenu }
            }

        } detail: {
            // ── Detail column — only used for level editor ─────────────────
            if case .levels = selectedSidebarItem,
               let selectedId = selectedLevelId,
               contentStore.levels.contains(where: { $0.id == selectedId }) {
                LevelEditorView(level: contentStore.levelBinding(id: selectedId))
                    .id(selectedId)
            } else {
                ContentUnavailableView {
                    Label("No Level Selected", systemImage: "square.stack.3d.up")
                } description: {
                    Text("Select a level from the list to edit it")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingNewLevelSheet) {
            NewLevelSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NewScriptSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewTriggerSheet) {
            NewTriggerSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewNPCSheet) {
            NewNPCSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(contentStore: contentStore, isPresented: $showingExportSheet)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView(
                contentStore: contentStore,
                isPresented: $showingImportSheet,
                importText: $importText,
                showingAlert: $showingImportAlert,
                alertMessage: $importAlertMessage
            )
        }
    }

    @ToolbarContentBuilder
    private var exportImportMenu: some ToolbarContent {
        ToolbarItem {
            Menu {
                Button { showingExportSheet = true } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                Button { showingImportSheet = true } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }
}
#endif
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD"
```

Expected: MacContentView compiles. Remaining errors should only be in `ContentListView.swift` and `TriggerScriptsView.swift`.

- [ ] **Step 3: Commit**

```bash
git add LevelGenerator/Views/macOS/MacContentView.swift
git commit -m "feat: update MacContentView — 4 sidebar sections (Levels/Scripts/Triggers/NPCs), new content routing"
```

---

## Task 10: Update ContentListView (iOS) and remove dead code

**Files:**
- Modify: `LevelGenerator/Views/Main/ContentListView.swift`
- Delete: `LevelGenerator/Views/Main/TriggerScriptsView.swift`

- [ ] **Step 1: Replace ContentListView.swift**

```swift
import SwiftUI

struct ContentListView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var selectedLevel: SavedLevel?

    enum Section: String, CaseIterable {
        case levels = "Levels"
        case scripts = "Scripts"
        case triggers = "Triggers"
        case npcs = "NPCs"
    }

    @State private var activeSection: Section = .levels
    @State private var showingNewTriggerSheet = false
    @State private var showingNewScriptSheet = false
    @State private var showingNewNPCSheet = false

    var body: some View {
        List {
            Picker("Section", selection: $activeSection) {
                ForEach(Section.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)

            switch activeSection {
            case .levels:
                ForEach(contentStore.levels) { level in
                    #if os(iOS)
                    NavigationLink {
                        LevelEditorView(level: contentStore.levelBinding(id: level.id))
                    } label: {
                        LevelRow(level: level)
                    }
                    #else
                    LevelRow(level: level)
                        .onTapGesture { selectedLevel = level }
                        .background(selectedLevel?.id == level.id ? Color.blue.opacity(0.1) : Color.clear)
                    #endif
                }
                .onDelete { contentStore.deleteLevel(at: $0) }

            case .scripts:
                ForEach(contentStore.scripts) { script in
                    #if os(iOS)
                    NavigationLink {
                        ScriptView(script: contentStore.scriptBinding(id: script.id))
                    } label: {
                        Text(script.name).font(.headline)
                    }
                    #else
                    Text(script.name)
                    #endif
                }
                .onDelete { contentStore.deleteScript(at: $0) }

            case .triggers:
                ForEach(contentStore.triggers) { trigger in
                    #if os(iOS)
                    NavigationLink {
                        TriggerDetailView(
                            trigger: contentStore.triggerBinding(id: trigger.id),
                            availableScriptNames: contentStore.scripts.map { $0.name }
                        )
                    } label: {
                        Text(trigger.name).font(.headline)
                    }
                    #else
                    Text(trigger.name)
                    #endif
                }
                .onDelete { contentStore.deleteTrigger(at: $0) }

            case .npcs:
                ForEach(contentStore.npcs) { npc in
                    #if os(iOS)
                    NavigationLink {
                        NPCDetailView(
                            npc: contentStore.npcBinding(id: npc.id),
                            availableScriptNames: contentStore.scripts.map { $0.name }
                        )
                    } label: {
                        Text(npc.name).font(.headline)
                    }
                    #else
                    Text(npc.name)
                    #endif
                }
                .onDelete { contentStore.deleteNPC(at: $0) }
            }
        }
        #if os(iOS)
        .navigationTitle("Content")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    switch activeSection {
                    case .levels: showingNewLevelSheet = true
                    case .scripts: showingNewScriptSheet = true
                    case .triggers: showingNewTriggerSheet = true
                    case .npcs: showingNewNPCSheet = true
                    }
                } label: { Image(systemName: "plus") }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingExportSheet = true } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    Button { showingImportSheet = true } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NavigationStack { NewScriptSheet(contentStore: contentStore) }
        }
        .sheet(isPresented: $showingNewTriggerSheet) {
            NavigationStack { NewTriggerSheet(contentStore: contentStore) }
        }
        .sheet(isPresented: $showingNewNPCSheet) {
            NavigationStack { NewNPCSheet(contentStore: contentStore) }
        }
        #endif
    }
}
```

- [ ] **Step 2: Delete TriggerScriptsView.swift**

```bash
rm LevelGenerator/Views/Main/TriggerScriptsView.swift
```

Then remove the file from the Xcode project by opening `LevelGenerator.xcodeproj` in Xcode, finding `TriggerScriptsView.swift` in the file navigator, right-clicking → Delete → Move to Trash.

Alternatively via command line — open the project file and remove the reference:
```bash
# After deleting the file, Xcode will show a missing file warning.
# Open the project in Xcode and delete the red file reference from the navigator.
```

- [ ] **Step 3: Build — expect clean**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED` with no errors.

- [ ] **Step 4: Run all tests**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | grep -E "Test.*passed|Test.*failed|error:|BUILD"
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add LevelGenerator/Views/Main/ContentListView.swift
git commit -m "feat: update ContentListView — 4-section picker (Levels/Scripts/Triggers/NPCs), iOS routing"
```

```bash
git add -A
git commit -m "chore: remove TriggerScriptsView — replaced by TriggerDetailView"
```

---

## Self-Review Checklist

- [x] **Spec coverage**: SavedScript ✓, SavedTrigger ✓, SavedNPC ✓, ContentStore CRUD ✓, SidebarItem ✓, ScriptLuaGenerator trigger/npc ✓, ScriptView video/screen ✓, TriggerDetailView ✓, NPCDetailView ✓, MacContentView 4 sections ✓, iOS ContentListView ✓, Export/Import ✓
- [x] **No placeholders**: all steps contain actual code
- [x] **Type consistency**: `SavedScript.SavedDialog(video:text:key:screen:)` used throughout; `ScriptLuaGenerator.lua(for trigger:)` and `lua(for npc:)` consistent with tests; `contentStore.scriptBinding(id:)` (not `triggerId:scriptId:`) used in all call sites
