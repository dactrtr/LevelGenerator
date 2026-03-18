# Dialog Editor Improvements — Design Spec

**Date:** 2026-03-18
**Project:** LevelGenerator (SwiftUI macOS/iOS)
**Scope:** Improve the script/dialog editor. No changes to level editor, room map, or export/import system.

---

## Problem

The current `ScriptView` mixes dialog authoring and conditional script editing in the same center column. When building conditionals, the user must type the target script name manually — leading to typos that silently produce broken game output. There is no connection between the names stored in the LDtk project and what the editor offers.

---

## Goal

1. Load an LDtk JSON file once to extract all script names referenced in trigger entities.
2. Use those names as a picker (instead of a free-text field) when selecting the target script in conditional entries.
3. Separate conditional editing from dialog editing so each has its own focused space.

---

## Architecture

### New: `LDtkScriptNameExtractor`

A pure value-type struct with no dependencies. Accepts `Data` (raw JSON bytes) and returns `[String]`.

**Parsing rules:**
- Extracts names from `entities.Triggers[].customFields.script` (direct string).
- Extracts names from `entities.Triggers[].customFields.conditionalScripts[]` — split on the **first colon only**, take right side, strip trailing `!`, drop empty results silently.
- Supports two formats:
  - **Room format** (`data.json`): triggers at `entities.Triggers[]`.
  - **Project format** (`.ldtk`): triggers found in `levels[].layerInstances[].entityInstances[]` where `__identifier == "Triggers"`.
  - Tries project format first. "No triggers found" means no `entityInstances` with `__identifier == "Triggers"` exist. Falls back to room format.
- Returns names deduped, sorted with `localizedStandardCompare`.
- **Zero results is a success.** Returns `[]` silently.

**Errors:** throws only on `Data(contentsOf:)` failure or `JSONSerialization` failure.

### Changes to `ContentStore`

Two new `@Published` properties:

```swift
@Published var ldtkScriptNames: [String] = []
@Published var ldtkFileName: String? = nil
```

Persistence: `ldtkScriptNames` stored via `UserDefaults.set(_:forKey: "ldtkScriptNames")`, loaded via `UserDefaults.stringArray(forKey:) ?? []`. `ldtkFileName` stored/loaded via `UserDefaults.set/string(forKey: "ldtkFileName")`.

The two new properties are loaded in `init()` alongside the existing `loadContent()` call:
```swift
ldtkScriptNames = UserDefaults.standard.stringArray(forKey: "ldtkScriptNames") ?? []
ldtkFileName = UserDefaults.standard.string(forKey: "ldtkFileName")
```

New method on `ContentStore` (called from the injected `contentStore` reference in views — not a local helper):

```swift
func loadLDtkNames(from url: URL) throws
```

Reads file data, runs `LDtkScriptNameExtractor`, updates `ldtkScriptNames` and `ldtkFileName = url.lastPathComponent`, then persists:
```swift
UserDefaults.standard.set(ldtkScriptNames, forKey: "ldtkScriptNames")
UserDefaults.standard.set(ldtkFileName, forKey: "ldtkFileName")
```

**Stale filename:** display hint only, not revalidated at launch.

### Changes to `MacContentView` (toolbar + status label)

**Button:** `"Cargar LDtk…"` added to the **existing `ToolbarItemGroup`** in the `content:` closure (alongside Add, Delete, More). Visible only when `selectedSection == .scripts`.

**File importer:** `.fileImporter(isPresented:allowedContentTypes:onCompletion:)` using `[.json]` as allowed content types. LDtk files are plain JSON — the OS maps `.ldtk` to `public.json` on macOS; no custom `UTType` declaration needed.

**Error state:** two new `@State` properties in `MacContentView`:
```swift
@State private var showingLDtkErrorAlert = false
@State private var ldtkErrorMessage = ""
```
On `loadLDtkNames` failure: set both, show `.alert("Error al cargar LDtk", isPresented: $showingLDtkErrorAlert) { Button("OK") {} } message: { Text(ldtkErrorMessage) }` added alongside the existing `.alert` in `MacContentView`.

**Status label:** inside the `content:` closure, wrap the existing `List { ... }` in a `VStack(spacing: 0)`. Add a `Text` below the `List`:

```swift
VStack(spacing: 0) {
    List { ... }
        .frame(maxHeight: .infinity)
    if selectedSection == .scripts, let name = contentStore.ldtkFileName {
        Text("\(name) · \(contentStore.ldtkScriptNames.count) scripts")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(6)
    }
}
```

### Changes to `ScriptView`

**Deleted entirely (type + all usages):**
- The `CenterMode` enum declaration in `ConditionalScriptsEditorView.swift` (lines 3–7) — delete the type.
- `@State var centerMode: CenterMode` in `ScriptView.swift` — delete the property.
- `Picker("", selection: $centerMode)` and all `if centerMode == .dialogs / else` branching in `ScriptView.swift` — delete both.
After these deletions, `CenterMode` has no remaining usages or declaration in the project.

**Center column:** renders the dialog `ForEach` unconditionally — no mode toggle.

**Toolbar:** the existing `ToolbarItem(placement: .primaryAction)` containing Save is replaced with a `ToolbarItemGroup(placement: .primaryAction)` containing both buttons:

```swift
ToolbarItemGroup(placement: .primaryAction) {
    Button("Condicionales (\(conditionalScripts.count))") {
        showConditionals = true
    }
    Button("Save") { ... }  // existing Save logic unchanged
}
```

**Sheet:**
```swift
@State var showConditionals = false
// ...
.sheet(isPresented: $showConditionals) {
    ConditionalScriptsEditorView(
        conditions: $conditionalScripts,
        availableScriptNames: availableScriptNames  // same param ScriptView already holds
    )
    .frame(minWidth: 800, minHeight: 500)  // prevents macOS sheet from collapsing
}
```

`ScriptView` keeps `@State var conditionalScripts: [ConditionalScript]`. Edits in the sheet mutate the binding directly. Save reads `self.conditionalScripts` — always up to date.

Left-column output block unchanged.

### Changes to `ConditionalScriptsEditorView`

- `@Environment(\.dismiss) var dismiss` added.
- `"Cerrar"` button added as the **last item** in the header `HStack` (after the existing "Agregar condición" button, at the trailing edge):

```swift
Button("Cerrar") { dismiss() }
    .buttonStyle(.bordered)
```

No cancel/rollback path — edits are live in the binding.

### Changes to `ConditionalScriptRowView`

**Script destino field** — replace the existing `VStack` at lines 72–86 with:

```swift
// When availableScriptNames is non-empty:
// condition is @Binding var condition: ConditionalScript — direct mutation is valid
Menu(condition.scriptName.isEmpty ? "Seleccionar script" : condition.scriptName) {
    ForEach(availableScriptNames, id: \.self) { name in
        Button(name) { condition.scriptName = name }
    }
}
.frame(width: 145)

// When availableScriptNames is empty (shown instead):
VStack(alignment: .leading, spacing: 2) {
    TextField("Script", text: $condition.scriptName)
        .textFieldStyle(.roundedBorder)
        .frame(width: 145)
    Text("Cargá un archivo LDtk para usar autocompletado")
        .font(.caption2)
        .foregroundStyle(.secondary)
}
```

The warning label `"⚠️ Script no existe"` is **removed in both branches**. When `availableScriptNames` is non-empty, the Menu replaces the need for it. When empty, the warning cannot fire (no list to check against).

### Call-site changes

`MacContentView.swift` (~line 129):
```swift
// Before:
availableScriptNames: contentStore.scripts.map { $0.name }
// After:
availableScriptNames: contentStore.ldtkScriptNames
```

`ContentListView.swift` (iOS): same replacement wherever `ScriptView` is instantiated.

**iOS `fileImporter` placement:** The `.fileImporter` modifier and its associated `@State` properties (`showingLDtkFilePicker`, `showingLDtkErrorAlert`, `ldtkErrorMessage`) are attached **directly to `ContentListView`**, not to `iOSContentView`. The toolbar button and the importer live in the same view.

**Behavior when no LDtk file is loaded:** `ldtkScriptNames` defaults to `[]`, so `ConditionalScriptRowView` shows the TextField fallback with the "Cargá un archivo LDtk" caption. This is intentional — the user must load a file to get the picker.

---

## Data Flow

```
User taps "Cargar LDtk…"
  → fileImporter picks URL
  → contentStore.loadLDtkNames(from:)
    → LDtkScriptNameExtractor → [String]
    → ldtkScriptNames + ldtkFileName persisted
  → status label updates / error alert on failure

User opens ScriptView → edits dialogs (center column, no toggle)
User taps "Condicionales (N)"   ← N is live count
  → showConditionals = true
  → sheet: ConditionalScriptsEditorView(conditions: $conditionalScripts,
                                         availableScriptNames: availableScriptNames)
  → each row: Menu (names available) or TextField (empty)
  → edits mutate $conditionalScripts directly
  → user taps "Cerrar" → dismiss() → sheet closes
  → left column output regenerates

User taps "Save"
  → SavedScript.update(with: self) reads conditionalScripts
  → ContentStore persists
```

---

## What Does NOT Change

- `LevelEditorView`, `MapView`, `RoomConnectionMapView`
- `SavedLevel`, `PlacedItem`, `SavedScript`, `ConditionalScript`, `PlayerVariable` models
- Export / Import JSON system
- Dialog input panel (right column of `ScriptView`)
- Left column outputs (Lua, localization, conditionalScripts block)

---

## Out of Scope

- Writing back to `script.lua` or LDtk JSON
- Showing dialog text from `en.strings`
- Browsing rooms/triggers from LDtk
- Any level editor changes
