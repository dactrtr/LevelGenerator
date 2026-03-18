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
3. The UI reflects this hierarchy: sidebar lists triggers, the content column lists scripts within the selected trigger.
4. Copy buttons on each script row let the user copy the Lua block or localization strings for that script without opening the editor.

---

## What Does NOT Change

- `SavedLevel`, `PlacedItem`, level editor, room map
- `ConditionalScript` model and its `conditionString` computed property
- `PlayerVariable` list
- `ScriptView` three-column layout (left outputs, center dialog list, right input form)
- Dialog Lua generation and localization generation logic (moved to `ScriptLuaGenerator`, but content unchanged)
- Export/import UI sheets (`ExportView`, `ImportView`)

**Note on `PlacedItem`:** `PlacedItem` continues to reference scripts by name via `triggerScriptName`. The level editor does not need to know which trigger owns a script — the name is resolved at game runtime. No changes to `PlacedItem` or `LevelEditorView`.

---

## Data Migration

**Fresh start.** The old `savedScripts` UserDefaults key is abandoned; no migration is attempted. On first launch with the new build, `triggers` loads as `[]`. Old script data is effectively discarded.

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

- Delete `var conditionalScripts: [ConditionalScript]`
- Delete `conditionalScripts` from `CodingKeys`
- Delete `conditionalScripts` from `init(id:name:dialogs:conditionalScripts:)` — new signature: `init(id: UUID = UUID(), name: String, dialogs: [SavedDialog] = [])`
- Delete the custom `init(from decoder:)` — with fresh start there is no backward-compat concern, use synthesized Codable
- In `mutating func update(with scriptView: ScriptView)`: delete the line `conditionalScripts = scriptView.scriptConditionalScripts`

### Modified `ScriptView`

Remove all conditional-related state and UI:

- Delete `var availableScriptNames: [String] = []` parameter
- Delete `@State private var conditionalScripts: [ConditionalScript]`
- Delete `@State private var showConditionals: Bool`
- Delete `var scriptConditionalScripts: [ConditionalScript]` computed property
- Delete `var generatedConditionalScripts: String` computed property
- Delete the "Conditional Scripts" `GroupBox` from the left column
- Delete the `.sheet(isPresented: $showConditionals)` block
- Delete the "Condicionales (N)" `Button` from the toolbar — toolbar now has only "Save"
- Replace `generatedLuaScript` and `generatedLocalization` computed properties with calls to `ScriptLuaGenerator.lua(for:)` and `ScriptLuaGenerator.localization(for:)`

### New helper: `ScriptLuaGenerator`

New file: `LevelGenerator/Models/ScriptLuaGenerator.swift`

The generation logic is moved verbatim from `ScriptView`'s computed properties:

```swift
enum ScriptLuaGenerator {
    static func lua(for script: SavedScript) -> String {
        // same logic as ScriptView.generatedLuaScript
        // uses script.name and script.dialogs
    }

    static func localization(for script: SavedScript) -> String {
        // same logic as ScriptView.generatedLocalization
        // uses script.dialogs
    }
}
```

`ScriptView` calls these instead of defining them inline. The script row copy buttons (see below) also use this helper.

### Changes to `ContentStore`

**Replaced:**
- `@Published var scripts: [SavedScript]` → `@Published var triggers: [SavedTrigger]`
- `private let scriptsKey = "savedScripts"` → `private let triggersKey = "savedTriggers"`

**Removed entirely:**
- `@Published var ldtkScriptNames: [String]`
- `@Published var ldtkFileName: String?`
- `private let ldtkScriptNamesKey`, `private let ldtkFileNameKey`
- `func loadLDtkNames(from url: URL) throws`
- `addScript`, `updateScript`, `deleteScript`, `scriptBinding(id:)` (old flat-list versions)
- LDtk UserDefaults loading from `init()`

**Added — trigger CRUD:**
```swift
func addTrigger(_ trigger: SavedTrigger)
func updateTrigger(at index: Int, with trigger: SavedTrigger)
func deleteTrigger(at offsets: IndexSet)   // cascade-deletes all scripts inside
func triggerBinding(id: UUID) -> Binding<SavedTrigger>
```

`deleteTrigger` removes the trigger and all nested scripts. Level editor script-name references become stale silently (name resolution is the game engine's responsibility).

**Added — script CRUD within a trigger:**
```swift
func addScript(_ script: SavedScript, to triggerId: UUID)
func deleteScript(scriptId: UUID, from triggerId: UUID)
func scriptBinding(triggerId: UUID, scriptId: UUID) -> Binding<SavedScript>
```

`scriptBinding` implementation:
```swift
func scriptBinding(triggerId: UUID, scriptId: UUID) -> Binding<SavedScript> {
    Binding(
        get: {
            guard let ti = self.triggers.firstIndex(where: { $0.id == triggerId }),
                  let si = self.triggers[ti].scripts.firstIndex(where: { $0.id == scriptId })
            else { return SavedScript(id: scriptId, name: "") }
            return self.triggers[ti].scripts[si]
        },
        set: {
            guard let ti = self.triggers.firstIndex(where: { $0.id == triggerId }),
                  let si = self.triggers[ti].scripts.firstIndex(where: { $0.id == scriptId })
            else { return }
            self.triggers[ti].scripts[si] = $0
            self.saveContent()
        }
    )
}
```

**Updated `ExportData`:**
```swift
struct ExportData: Codable {
    let levels: [SavedLevel]
    let triggers: [SavedTrigger]
    let nodeStyles: [NodeStyle]
    let version: String
}
```

Updated `mergeFromJSON` deduplication:
```swift
let existingTriggerIds = Set(triggers.map { $0.id })
let newTriggers = importedData.triggers.filter { !existingTriggerIds.contains($0.id) }
triggers.append(contentsOf: newTriggers)
```

Old JSON files that have `"scripts"` but no `"triggers"` will fail to decode and `importFromJSON` returns `false` (existing behavior for malformed data).

### Removed files

- `LevelGenerator/Parsers/LDtkScriptNameExtractor.swift`
- `LevelGeneratorTests/LDtkScriptNameExtractorTests.swift`

Both removed from disk and from `project.pbxproj` compile sources.

---

## Navigation Model

### `SidebarItem` (replaces `ContentSection`)

`ContentSection.swift` is replaced in-place:

```swift
// ContentSection.swift — renamed to SidebarItem, same file
enum SidebarItem: Hashable {
    case levels
    case trigger(UUID)
}
```

`ContentManagerView` changes:
- `@State private var selectedSection: ContentSection = .scripts` → `@State private var selectedSidebarItem: SidebarItem = .levels`
- Connections toolbar button condition: `if case .levels = selectedSidebarItem`
- Both `MacContentView` and `iOSContentView` receive `sidebarItem: $selectedSidebarItem` instead of `selectedSection`
- `showingNewScriptSheet` binding removed (no longer used by MacContentView — new-script creation is trigger-scoped inside MacContentView)

---

## macOS: `MacContentView`

### Signature change

```swift
struct MacContentView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem    // replaces selectedSection
    @Binding var showingNewLevelSheet: Bool
    // showingNewScriptSheet removed
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var importText: String
    @Binding var showingImportAlert: Bool
    @Binding var importAlertMessage: String
```

### Sidebar

```swift
NavigationSplitView { // sidebar
    List(selection: $selectedSidebarItem) {
        NavigationLink(value: SidebarItem.levels) {
            Label("Levels", systemImage: "square.stack.3d.up")
        }
        Section("Triggers") {
            ForEach(contentStore.triggers) { trigger in
                NavigationLink(value: SidebarItem.trigger(trigger.id)) {
                    Text(trigger.name)
                }
            }
        }
    }
    .navigationTitle("Content")
    .listStyle(.sidebar)
    .toolbar {
        // "+" adds a level when levels selected, or a trigger when triggers section active
        Button { handleAdd() } label: { Label("Add", systemImage: "plus") }
    }
}
```

`handleAdd()`:
- If `selectedSidebarItem == .levels` → `showingNewLevelSheet = true`
- Otherwise → `showingNewTriggerSheet = true`

### Content column (trigger selected)

When `selectedSidebarItem == .trigger(id)`:

```swift
// State
@State private var selectedScriptId: UUID?
@State private var showConditionals = false
@State private var showingNewScriptSheet = false

// Resolved trigger via binding
let trigger = contentStore.triggerBinding(id: id)

VStack(spacing: 0) {
    List(selection: $selectedScriptId) {
        ForEach(trigger.wrappedValue.scripts) { script in
            NavigationLink(value: script.id) {
                ScriptRowWithCopyButtons(script: script)
            }
        }
        .onDelete { offsets in
            // map offsets → script IDs and call deleteScript
        }
    }
    .frame(maxHeight: .infinity)
}
.navigationTitle(trigger.wrappedValue.name)
.toolbar {
    ToolbarItemGroup {
        Button { showingNewScriptSheet = true } label: {
            Label("Add Script", systemImage: "plus")
        }

        if selectedScriptId != nil {
            Button(role: .destructive) {
                if let sid = selectedScriptId {
                    contentStore.deleteScript(scriptId: sid, from: id)
                    selectedScriptId = nil
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }

        Button("Condicionales (\(trigger.wrappedValue.conditionalScripts.count))") {
            showConditionals = true
        }

        Menu {
            Button { showingExportSheet = true } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            Button { showingImportSheet = true } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
        } label: { Label("More", systemImage: "ellipsis.circle") }
    }
}
.sheet(isPresented: $showConditionals) {
    ConditionalScriptsEditorView(
        conditions: Binding(
            get: { trigger.wrappedValue.conditionalScripts },
            set: { trigger.conditionalScripts.wrappedValue = $0 }
        ),
        availableScriptNames: trigger.wrappedValue.scripts.map { $0.name }
    )
    .frame(minWidth: 800, minHeight: 500)
}
.sheet(isPresented: $showingNewScriptSheet) {
    NewScriptInTriggerSheet { name in
        contentStore.addScript(SavedScript(name: name), to: id)
    }
}
```

**Conditionals sheet binding:** the sheet binds directly to `trigger.conditionalScripts` via `triggerBinding`. Edits are written back through `ContentStore.saveContent()` when the binding is set. No separate "Save" needed — same live-binding pattern as the existing conditional editor.

### Detail column

```swift
if let sid = selectedScriptId,
   trigger.wrappedValue.scripts.contains(where: { $0.id == sid }) {
    ScriptView(script: contentStore.scriptBinding(triggerId: id, scriptId: sid))
        .id(sid)
} else {
    ContentUnavailableView { Label("No Script Selected", ...) }
}
```

### New sheets

**`NewTriggerSheet`** — replaces `NewScriptSheet`:
```swift
struct NewTriggerSheet: View {
    @Environment(\.dismiss) var dismiss
    var contentStore: ContentStore
    @State private var name = ""
    var body: some View {
        Form {
            TextField("Trigger name", text: $name)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    guard !name.isEmpty else { return }
                    contentStore.addTrigger(SavedTrigger(name: name))
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
```

**`NewScriptInTriggerSheet`**:
```swift
struct NewScriptInTriggerSheet: View {
    @Environment(\.dismiss) var dismiss
    var onConfirm: (String) -> Void
    @State private var name = ""
    var body: some View {
        Form {
            TextField("Script name", text: $name)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    guard !name.isEmpty else { return }
                    onConfirm(name)
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
```

No duplicate name validation — names are informational.

---

## Script Row with Copy Buttons

New view `ScriptRowWithCopyButtons`:

```swift
struct ScriptRowWithCopyButtons: View {
    let script: SavedScript
    var body: some View {
        HStack {
            Text(script.name)
            Spacer()
            Button("Lua") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ScriptLuaGenerator.lua(for: script), forType: .string)
            }
            .buttonStyle(.bordered)
            Button("Strings") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ScriptLuaGenerator.localization(for: script), forType: .string)
            }
            .buttonStyle(.bordered)
        }
    }
}
```

For iOS use `UIPasteboard.general.string = ...` inside `#if os(iOS)`.

No toast/confirmation needed — the copy action is instant and reversible.

---

## iOS: `ContentListView`

iOS uses a two-level navigation: first pick a trigger, then see its scripts.

### Changes to `ContentListView`

```swift
struct ContentListView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem    // replaces selectedSection
    @Binding var showingNewLevelSheet: Bool
    // showingNewScriptSheet/selectedScript/ldtk state removed
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var selectedLevel: SavedLevel?

    @State private var selectedTrigger: SavedTrigger?
```

The segmented picker changes from `ContentSection` to:
```swift
Picker("Section", selection: Binding(
    get: {
        if case .levels = selectedSidebarItem { return 0 } else { return 1 }
    },
    set: { selectedSidebarItem = $0 == 0 ? .levels : .trigger(UUID()) }
)) {
    Text("Levels").tag(0)
    Text("Triggers").tag(1)
}
.pickerStyle(.segmented)
```

When "Triggers" is selected, shows all triggers:
```swift
ForEach(contentStore.triggers) { trigger in
    NavigationLink {
        TriggerScriptsView(
            trigger: contentStore.triggerBinding(id: trigger.id),
            contentStore: contentStore
        )
    } label: {
        Text(trigger.name)
    }
}
.onDelete { contentStore.deleteTrigger(at: $0) }
```

The `+` toolbar button when triggers is selected adds a trigger (shows `NewTriggerSheet`). Remove all LDtk state and file importer from this view.

### New iOS view: `TriggerScriptsView`

```swift
struct TriggerScriptsView: View {
    @Binding var trigger: SavedTrigger
    @ObservedObject var contentStore: ContentStore
    @State private var showConditionals = false
    @State private var showingNewScriptSheet = false

    var body: some View {
        List {
            ForEach(trigger.scripts) { script in
                NavigationLink {
                    ScriptView(script: contentStore.scriptBinding(
                        triggerId: trigger.id, scriptId: script.id))
                } label: {
                    ScriptRowWithCopyButtons(script: script)
                }
            }
            .onDelete { offsets in
                offsets.map { trigger.scripts[$0].id }
                       .forEach { contentStore.deleteScript(scriptId: $0, from: trigger.id) }
            }
        }
        .navigationTitle(trigger.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingNewScriptSheet = true } label: {
                    Image(systemName: "plus")
                }
                Button("Cond. (\(trigger.conditionalScripts.count))") {
                    showConditionals = true
                }
            }
        }
        .sheet(isPresented: $showConditionals) {
            ConditionalScriptsEditorView(
                conditions: $trigger.conditionalScripts,
                availableScriptNames: trigger.scripts.map { $0.name }
            )
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NewScriptInTriggerSheet { name in
                contentStore.addScript(SavedScript(name: name), to: trigger.id)
            }
        }
    }
}
```

---

## File Map

| Action | File | What changes |
|--------|------|-------------|
| Modify | `LevelGenerator/Models/SavedContent.swift` | Add `SavedTrigger`; strip `SavedScript.conditionalScripts`; update `ContentStore` |
| Modify | `LevelGenerator/Models/ContentSection.swift` | Replace `ContentSection` with `SidebarItem` |
| Create | `LevelGenerator/Models/ScriptLuaGenerator.swift` | New pure helper extracted from `ScriptView` |
| Modify | `LevelGenerator/Views/ScriptView.swift` | Remove all conditional code; use `ScriptLuaGenerator` |
| Modify | `LevelGenerator/Views/ConditionalScriptsEditorView.swift` | No structural change; already has `availableScriptNames` + dismiss |
| Modify | `LevelGenerator/Views/macOS/MacContentView.swift` | New sidebar/content/detail wiring for triggers |
| Create | `LevelGenerator/Views/macOS/NewTriggerSheet.swift` | Replaces `NewScriptSheet` on macOS |
| Create | `LevelGenerator/Views/Shared/NewScriptInTriggerSheet.swift` | Shared between platforms |
| Create | `LevelGenerator/Views/Shared/ScriptRowWithCopyButtons.swift` | Shared between platforms |
| Modify | `LevelGenerator/Views/Main/ContentListView.swift` | iOS: triggers list, remove LDtk state |
| Create | `LevelGenerator/Views/Main/TriggerScriptsView.swift` | iOS: scripts within trigger |
| Modify | `LevelGenerator/Views/Main/ContentManagerView.swift` | Use `SidebarItem` instead of `ContentSection` |
| Delete | `LevelGenerator/Parsers/LDtkScriptNameExtractor.swift` | Removed |
| Delete | `LevelGeneratorTests/LDtkScriptNameExtractorTests.swift` | Removed |

---

## Data Flow

```
Sidebar: tap trigger "lamp"
  → selectedSidebarItem = .trigger(lamp.id)
  → content column shows [big, tiny] each with [Lua] [Strings] buttons

[Lua] on "big"
  → ScriptLuaGenerator.lua(for: big) → pasteboard

[Strings] on "big"
  → ScriptLuaGenerator.localization(for: big) → pasteboard

Tap "big" row
  → selectedScriptId = big.id
  → detail: ScriptView(script: scriptBinding(triggerId: lamp.id, scriptId: big.id))

ScriptView: edit dialogs → Save
  → scriptBinding writes back → ContentStore.saveContent()

Toolbar "Condicionales (1)"
  → sheet: ConditionalScriptsEditorView(
       conditions: $trigger.conditionalScripts,
       availableScriptNames: ["big", "tiny"])
  → user picks "big" from Menu
  → Cerrar → binding committed → saveContent()
```

---

## Out of Scope

- Reordering scripts or triggers
- Renaming scripts after creation (name is set at creation time)
- Showing which conditionals reference a given script in the detail view (the detail view focuses on dialog authoring; conditionals are managed at the trigger level via the "Condicionales" button)
- Migrating old `savedScripts` data
- Writing back to game files or LDtk JSON
