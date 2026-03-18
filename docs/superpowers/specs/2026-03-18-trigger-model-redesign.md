# Trigger Model Redesign — Design Spec

**Date:** 2026-03-18
**Project:** LevelGenerator (SwiftUI macOS/iOS)
**Scope:** Replace the flat `scripts` model with a `triggers` hierarchy. Each trigger owns its scripts and its conditionals. No LDtk loading.

---

## Problem

The current model stores scripts as a flat list. Conditional entries reference target scripts by name, but there is no structural link between a set of scripts and the conditionals that use them. In practice each trigger in the game owns a set of scripts and a set of conditionals that reference those scripts — the flat model cannot express this.

---

## Goal

1. Introduce `SavedTrigger` as the new top-level entity. Each trigger owns an array of `SavedScript` and an array of `ConditionalScript`.
2. The conditional script-name picker draws from the trigger's own scripts, not from an external file.
3. The UI reflects this hierarchy: sidebar lists triggers, the content column lists the scripts within the selected trigger.
4. Copy buttons on each script row let the user copy Lua or localization strings without opening the editor.

---

## What Does NOT Change

- `SavedLevel`, `PlacedItem`, level editor, room map, export/import structure for levels
- `ConditionalScript` model and its `conditionString` computed property
- `PlayerVariable` list
- `ScriptView` three-column layout (left outputs, center dialog list, right input form)
- Dialog generation (Lua + localization)

---

## Architecture

### New model: `SavedTrigger`

Added to `SavedContent.swift`:

```swift
struct SavedTrigger: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var scripts: [SavedScript]
    var conditionalScripts: [ConditionalScript]

    init(id: UUID = UUID(), name: String,
         scripts: [SavedScript] = [],
         conditionalScripts: [ConditionalScript] = []) {
        self.id = id
        self.name = name
        self.scripts = scripts
        self.conditionalScripts = conditionalScripts
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SavedTrigger, rhs: SavedTrigger) -> Bool { lhs.id == rhs.id }
}
```

### Modified model: `SavedScript`

`SavedScript` loses `conditionalScripts` entirely:
- Remove `var conditionalScripts: [ConditionalScript]`
- Remove from `init`, `CodingKeys`, and `update(with:)`
- The backward-compat decoder for the old `conditionalScripts` field is no longer needed (fresh start)

`SavedScript.update(with scriptView: ScriptView)` remains but only updates `name` and `dialogs`.

### Changes to `ContentStore`

**Replaced:**
- `@Published var scripts: [SavedScript]` → `@Published var triggers: [SavedTrigger]`
- `private let scriptsKey = "savedScripts"` → `private let triggersKey = "savedTriggers"`

**Removed entirely:**
- `@Published var ldtkScriptNames: [String]`
- `@Published var ldtkFileName: String?`
- `private let ldtkScriptNamesKey`
- `private let ldtkFileNameKey`
- `func loadLDtkNames(from url: URL) throws`
- `addScript`, `updateScript`, `deleteScript`, `scriptBinding(id:)`
- LDtk UserDefaults loading from `init()`

**Added — trigger CRUD:**
```swift
func addTrigger(_ trigger: SavedTrigger)
func updateTrigger(at index: Int, with trigger: SavedTrigger)
func deleteTrigger(at offsets: IndexSet)
func triggerBinding(id: UUID) -> Binding<SavedTrigger>
```

**Added — script CRUD within trigger:**
```swift
func addScript(_ script: SavedScript, to triggerId: UUID)
func deleteScript(at offsets: IndexSet, in triggerId: UUID)
func scriptBinding(triggerId: UUID, scriptId: UUID) -> Binding<SavedScript>
```

`scriptBinding` uses double `firstIndex` lookup: find trigger by id, then find script by id within it.

**Updated `ExportData`:**
```swift
struct ExportData: Codable {
    let levels: [SavedLevel]
    let triggers: [SavedTrigger]
    let nodeStyles: [NodeStyle]
    let version: String
}
```

`exportToJSON`, `importFromJSON`, `mergeFromJSON` updated accordingly. `mergeFromJSON` deduplicates triggers by id (same pattern as levels).

`saveContent` / `loadContent` use the `triggersKey`.

### Removed files

- `LevelGenerator/Parsers/LDtkScriptNameExtractor.swift`
- `LevelGeneratorTests/LDtkScriptNameExtractorTests.swift`

Both removed from disk and from `project.pbxproj` compile sources.

---

## Navigation Model

### `SidebarItem` enum (replaces `ContentSection`)

```swift
enum SidebarItem: Hashable {
    case levels
    case trigger(UUID)
}
```

The sidebar `List` has:
- A fixed `NavigationLink(value: SidebarItem.levels)` labeled "Levels"
- A `Section("Triggers")` with `ForEach(contentStore.triggers)` where each row is a `NavigationLink(value: SidebarItem.trigger(trigger.id))`

Sidebar selection: `@State private var selectedSidebarItem: SidebarItem?`

### Content column

- `selectedSidebarItem == .levels` → same level list as today
- `selectedSidebarItem == .trigger(id)` → list of `trigger.scripts`, each row is a `NavigationLink(value: script.id)` plus copy buttons

Content column selection: `@State private var selectedLevelId: UUID?` (kept) + `@State private var selectedScriptId: UUID?` (kept, now scoped to a trigger's scripts)

### Toolbar (content column, trigger selected)

```swift
ToolbarItemGroup {
    Button("+") { showingNewScriptSheet = true }

    if selectedScriptId != nil {
        Button(role: .destructive) { /* delete script from trigger */ } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    Button("Condicionales (\(trigger.conditionalScripts.count))") {
        showConditionals = true
    }

    Menu { Export / Import } label: { Label("More"...) }
}
```

### Sheet: new script

`NewScriptInTriggerSheet` — a simple sheet with a `TextField` for the script name. On confirm, calls `contentStore.addScript(SavedScript(name: name), to: triggerId)`.

### Sheet: conditionals

`.sheet(isPresented: $showConditionals)` presents:
```swift
ConditionalScriptsEditorView(
    conditions: $triggerConditionals,
    availableScriptNames: trigger.scripts.map { $0.name }
)
.frame(minWidth: 800, minHeight: 500)
```

`triggerConditionals` is a `@State` copy of `trigger.conditionalScripts` in the content view, written back to the store on dismiss. Alternatively, pass a binding via `triggerBinding(id:)`.

**Recommended:** use `triggerBinding(id:)` and pass `$trigger.conditionalScripts` directly, so no separate save step is needed.

### Detail column

`ScriptView` opens when a script is selected in the content column. Receives `scriptBinding(triggerId:scriptId:)`.

---

## Changes to `ScriptView`

- Remove `var availableScriptNames: [String]` parameter
- Remove `@State private var conditionalScripts`
- Remove `@State private var showConditionals`
- Remove `.sheet(isPresented: $showConditionals)` block
- Remove `generatedConditionalScripts` computed property
- Remove the "Conditional Scripts" `GroupBox` from the left column
- Remove "Condicionales (N)" button from toolbar — toolbar now has only "Save"
- `SavedScript.update(with:)` no longer touches `conditionalScripts`

---

## Script Row Copy Buttons

Each script row in the content column (when viewing a trigger's scripts) shows:

```
[script name]    [Lua]  [Strings]
```

- **[Lua]** — copies the result of `ScriptLuaGenerator.lua(for: script)` to the clipboard
- **[Strings]** — copies the result of `ScriptLuaGenerator.localization(for: script)` to the clipboard

The Lua and localization generation logic is extracted from `ScriptView`'s computed properties into a pure helper:

```swift
enum ScriptLuaGenerator {
    static func lua(for script: SavedScript) -> String { ... }
    static func localization(for script: SavedScript) -> String { ... }
}
```

`ScriptView` uses `ScriptLuaGenerator` for its left-column outputs (replaces the inline computed properties). The script rows in the content column use the same helper for the copy buttons.

`ScriptLuaGenerator` lives in `LevelGenerator/Models/ScriptLuaGenerator.swift`.

---

## iOS (`ContentListView`)

- Replace `ScriptView(... availableScriptNames: contentStore.ldtkScriptNames)` with `ScriptView(script: ...)` (no availableScriptNames param)
- Replace the scripts list with a trigger-aware list:
  - Shows the selected trigger's scripts (or a trigger picker if no trigger selected)
  - "Condicionales" button in toolbar when a trigger is selected
- Remove LDtk `@State` properties and `#if os(iOS)` LDtk block
- Add `NewScriptInTriggerSheet` support

---

## Data Flow

```
Sidebar: tap trigger "lamp"
  → selectedSidebarItem = .trigger(lamp.id)
  → content column shows [big, tiny] with [Lua] [Strings] buttons

Content column: tap [Lua] on "big"
  → ScriptLuaGenerator.lua(for: big) → pasteboard

Content column: tap [Strings] on "big"
  → ScriptLuaGenerator.localization(for: big) → pasteboard

Content column: tap "big"
  → selectedScriptId = big.id
  → detail shows ScriptView(script: scriptBinding(triggerId: lamp.id, scriptId: big.id))

ScriptView: edit dialogs, tap Save
  → scriptBinding writes back through ContentStore → persisted

Content column toolbar: tap "Condicionales (1)"
  → sheet: ConditionalScriptsEditorView(
       conditions: triggerBinding.conditionalScripts,
       availableScriptNames: ["big", "tiny"]
     )
  → user picks "big" from Menu
  → tap Cerrar → binding written back → ContentStore persisted
```

---

## Out of Scope

- Reordering scripts within a trigger
- Renaming scripts (name is set at creation)
- Showing trigger conditionals output in the detail view
- Any level editor changes
