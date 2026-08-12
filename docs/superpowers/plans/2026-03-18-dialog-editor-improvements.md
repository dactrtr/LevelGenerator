# Dialog Editor Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve the LevelGenerator script editor by loading LDtk JSON to extract script names, replacing the free-text conditional target field with a picker, and moving conditional editing to a dedicated sheet.

**Architecture:** Add a pure `LDtkScriptNameExtractor` struct, extend `ContentStore` with two persisted `@Published` properties, then make targeted edits to `ScriptView`, `ConditionalScriptsEditorView`, `ConditionalScriptRowView`, `MacContentView`, and `ContentListView`.

**Tech Stack:** Swift 5.9+, SwiftUI, Swift Testing framework (`import Testing`, `@Test`, `#expect`). macOS + iOS. No external dependencies.

---

## File Map

| Action | File | What changes |
|--------|------|-------------|
| Create | `LevelGenerator/Parsers/LDtkScriptNameExtractor.swift` | New pure struct — parses LDtk/data.json bytes into `[String]` |
| Create | `LevelGeneratorTests/LDtkScriptNameExtractorTests.swift` | Unit tests for the extractor |
| Modify | `LevelGenerator/Models/SavedContent.swift` | Add `@Published` properties + `loadLDtkNames` method to `ContentStore` |
| Modify | `LevelGenerator/Views/ScriptView.swift` | Delete `centerMode` state + picker + branching; add `showConditionals` state + toolbar button + sheet |
| Modify | `LevelGenerator/Views/ConditionalScriptsEditorView.swift` | Delete `CenterMode` enum (now safe — no usages remain); add `@Environment(\.dismiss)`; add "Cerrar" button; replace script-destino field in `ConditionalScriptRowView` |
| Modify | `LevelGenerator/Views/macOS/MacContentView.swift` | Add "Cargar LDtk…" button + fileImporter + error alert + status label; update `availableScriptNames` call-site |
| Modify | `LevelGenerator/Views/Main/ContentListView.swift` | Update iOS `availableScriptNames` call-site; add "Cargar LDtk…" toolbar button + fileImporter (iOS only) |

**Task order matters:** Task 3 (ScriptView) removes all usages of `CenterMode` first. Task 4 then safely deletes the `CenterMode` enum declaration. Do not reverse this order.

---

## Task 1: `LDtkScriptNameExtractor` (TDD)

**Files:**
- Create: `LevelGenerator/Parsers/LDtkScriptNameExtractor.swift`
- Create: `LevelGeneratorTests/LDtkScriptNameExtractorTests.swift`

- [ ] **Step 1: Create the `Parsers` folder and add files to Xcode targets**

In Xcode's project navigator:
1. Right-click the `LevelGenerator` group → New Group → name it `Parsers`
2. Right-click `Parsers` → New File → Swift File → name it `LDtkScriptNameExtractor.swift`
   - In the target membership dialog: check **`LevelGenerator`** (the app target). Do NOT check `LevelGeneratorTests`. `ContentStore` will call this type — it must be in the app target.
3. Right-click the `LevelGeneratorTests` group → New File → Swift File → name it `LDtkScriptNameExtractorTests.swift`
   - In the target membership dialog: check **`LevelGeneratorTests`** only.

Verify in Build Phases: `LDtkScriptNameExtractor.swift` appears under `LevelGenerator → Compile Sources` and `LDtkScriptNameExtractorTests.swift` appears under `LevelGeneratorTests → Compile Sources`.

- [ ] **Step 2: Write failing tests**

Replace the contents of `LevelGeneratorTests/LDtkScriptNameExtractorTests.swift`:

```swift
import Testing
@testable import LevelGenerator

struct LDtkScriptNameExtractorTests {

    // MARK: - Room format (data.json)

    @Test func roomFormat_extractsScriptField() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "giftFor100", "conditionalScripts": [] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names == ["giftFor100"])
    }

    @Test func roomFormat_extractsConditionalScriptNames() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "fallback", "conditionalScripts": ["isTiny:hugeXmas", "!isTiny:normalXmas!"] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names.contains("fallback"))
        #expect(names.contains("hugeXmas"))
        #expect(names.contains("normalXmas"))
        #expect(names.count == 3)
    }

    @Test func roomFormat_deduplicates() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "same", "conditionalScripts": ["x:same"] } },
              { "customFields": { "script": "same", "conditionalScripts": [] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names == ["same"])
    }

    @Test func roomFormat_sortedAlphabetically() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "zScript", "conditionalScripts": ["x:aScript"] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names == ["aScript", "zScript"])
    }

    @Test func roomFormat_dropsEmptyConditionalScriptName() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "ok", "conditionalScripts": ["isTiny:!", "x:valid"] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(!names.contains(""))
        #expect(names.contains("valid"))
        #expect(names.contains("ok"))
    }

    @Test func roomFormat_noTriggersKey_returnsEmpty() throws {
        let json = """{ "entities": {} }"""
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names.isEmpty)
    }

    @Test func roomFormat_nullScriptField_ignored() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": null, "conditionalScripts": [] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names.isEmpty)
    }

    // MARK: - LDtk project format

    @Test func ldtkFormat_extractsScriptNames() throws {
        let json = """
        {
          "levels": [{
            "layerInstances": [{
              "entityInstances": [{
                "__identifier": "Triggers",
                "fieldInstances": [
                  { "__identifier": "script", "__value": "introDialog" },
                  { "__identifier": "conditionalScripts", "__value": ["battery<20:lowPower"] }
                ]
              }]
            }]
          }]
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names.contains("introDialog"))
        #expect(names.contains("lowPower"))
    }

    @Test func ldtkFormat_fallsBackToRoomFormat_whenNoTriggerEntities() throws {
        let json = """
        {
          "levels": [{
            "layerInstances": [{
              "entityInstances": [{
                "__identifier": "Items",
                "fieldInstances": []
              }]
            }]
          }],
          "entities": {
            "Triggers": [
              { "customFields": { "script": "roomScript", "conditionalScripts": [] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names == ["roomScript"])
    }

    // MARK: - Error cases

    @Test func invalidJSON_throws() {
        let bad = Data("not json".utf8)
        #expect(throws: (any Error).self) {
            try LDtkScriptNameExtractor().extract(from: bad)
        }
    }

    @Test func emptyJSON_returnsEmpty() throws {
        let names = try LDtkScriptNameExtractor().extract(from: Data("{}".utf8))
        #expect(names.isEmpty)
    }
}
```

- [ ] **Step 3: Run tests — expect FAIL (type doesn't exist yet)**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' -only-testing:LevelGeneratorTests/LDtkScriptNameExtractorTests 2>&1 | tail -20
```

Expected: compiler error — `LDtkScriptNameExtractor` not found.

- [ ] **Step 4: Create the extractor**

Replace the contents of `LevelGenerator/Parsers/LDtkScriptNameExtractor.swift`:

```swift
import Foundation

struct LDtkScriptNameExtractor {

    /// Extract unique, sorted script names from LDtk JSON data.
    /// Supports both single-room data.json and top-level .ldtk project files.
    /// Throws only on invalid JSON. Zero results is a success.
    func extract(from data: Data) throws -> [String] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        var names: Set<String> = []

        // Try .ldtk project format first
        if let levels = root["levels"] as? [[String: Any]] {
            var foundTriggers = false
            for level in levels {
                let layerInstances = (level["layerInstances"] as? [[String: Any]]) ?? []
                for layer in layerInstances {
                    let entities = (layer["entityInstances"] as? [[String: Any]]) ?? []
                    for entity in entities {
                        guard (entity["__identifier"] as? String) == "Triggers" else { continue }
                        foundTriggers = true
                        let fields = (entity["fieldInstances"] as? [[String: Any]]) ?? []
                        collectFromLDtkFields(fields, into: &names)
                    }
                }
            }
            if foundTriggers {
                return sorted(names)
            }
            // No Triggers entities found — fall through to room format
        }

        // Room format (data.json): entities.Triggers[]
        let triggers = ((root["entities"] as? [String: Any])?["Triggers"] as? [[String: Any]]) ?? []
        for trigger in triggers {
            let fields = (trigger["customFields"] as? [String: Any]) ?? [:]
            if let script = fields["script"] as? String, !script.isEmpty {
                names.insert(script)
            }
            let conditionals = (fields["conditionalScripts"] as? [String]) ?? []
            for raw in conditionals {
                if let name = scriptName(from: raw) { names.insert(name) }
            }
        }

        return sorted(names)
    }

    // MARK: - Private

    private func collectFromLDtkFields(_ fields: [[String: Any]], into names: inout Set<String>) {
        for field in fields {
            guard let identifier = field["__identifier"] as? String else { continue }
            if identifier == "script",
               let value = field["__value"] as? String, !value.isEmpty {
                names.insert(value)
            } else if identifier == "conditionalScripts",
                      let values = field["__value"] as? [String] {
                for raw in values {
                    if let name = scriptName(from: raw) { names.insert(name) }
                }
            }
        }
    }

    /// "condition:scriptName!" → "scriptName". Returns nil if empty.
    private func scriptName(from raw: String) -> String? {
        guard let colonIdx = raw.firstIndex(of: ":") else { return nil }
        var name = String(raw[raw.index(after: colonIdx)...])
        if name.hasSuffix("!") { name = String(name.dropLast()) }
        return name.isEmpty ? nil : name
    }

    private func sorted(_ names: Set<String>) -> [String] {
        names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}
```

- [ ] **Step 5: Run tests — expect PASS**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' -only-testing:LevelGeneratorTests/LDtkScriptNameExtractorTests 2>&1 | tail -20
```

Expected: All 11 tests pass.

- [ ] **Step 6: Commit**

```bash
git add LevelGenerator/Parsers/LDtkScriptNameExtractor.swift LevelGeneratorTests/LDtkScriptNameExtractorTests.swift
git commit -m "feat: add LDtkScriptNameExtractor with TDD"
```

---

## Task 2: Extend `ContentStore`

**Files:**
- Modify: `LevelGenerator/Models/SavedContent.swift`

- [ ] **Step 1: Add `@Published` properties and key constants**

In `ContentStore`, add two key constants alongside the existing `levelsKey` and `scriptsKey` (around line 231):

```swift
private let ldtkScriptNamesKey = "ldtkScriptNames"
private let ldtkFileNameKey = "ldtkFileName"
```

Then add two `@Published` properties after `@Published var scripts: [SavedScript] = []` (around line 228):

```swift
@Published var ldtkScriptNames: [String] = []
@Published var ldtkFileName: String? = nil
```

- [ ] **Step 2: Load persisted values in `init()`**

In the `init()` body, add these two lines **after** the `loadContent()` call:

```swift
ldtkScriptNames = UserDefaults.standard.stringArray(forKey: ldtkScriptNamesKey) ?? []
ldtkFileName = UserDefaults.standard.string(forKey: ldtkFileNameKey)
```

- [ ] **Step 3: Add `loadLDtkNames` method**

Add this method to the `ContentStore` class body (e.g., after the `deleteScript` method):

```swift
func loadLDtkNames(from url: URL) throws {
    // Security-scoped resource access required for URLs from fileImporter
    let accessing = url.startAccessingSecurityScopedResource()
    defer { if accessing { url.stopAccessingSecurityScopedResource() } }

    let data = try Data(contentsOf: url)
    ldtkScriptNames = try LDtkScriptNameExtractor().extract(from: data)
    ldtkFileName = url.lastPathComponent
    UserDefaults.standard.set(ldtkScriptNames, forKey: ldtkScriptNamesKey)
    UserDefaults.standard.set(ldtkFileName, forKey: ldtkFileNameKey)
}
```

- [ ] **Step 4: Build to verify no compile errors**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add LevelGenerator/Models/SavedContent.swift
git commit -m "feat: add ldtkScriptNames and loadLDtkNames to ContentStore"
```

---

## Task 3: Refactor `ScriptView` (removes all `CenterMode` usages)

**Files:**
- Modify: `LevelGenerator/Views/ScriptView.swift`

**Do this task before Task 4.** This removes all usages of `CenterMode` in `ScriptView.swift`, making it safe to delete the `CenterMode` declaration in the next task.

- [ ] **Step 1: Delete `centerMode` state, picker, and branching**

In `ScriptView.swift`:

There are exactly three places in `ScriptView.swift` that reference `CenterMode`. Delete all three:

1. **State property** — delete the line: `@State private var centerMode: CenterMode = .dialogs`

2. **Picker block** — delete the entire `Picker("", selection: $centerMode)` block, including:
   - Both `Label` entries with `.tag(CenterMode.dialogs)` and `.tag(CenterMode.conditions)` inside it
   - The `.pickerStyle(.segmented)` + `.padding` chain
   - The `Divider()` that follows the picker

3. **If/else branch** — delete the entire `if centerMode == .dialogs { ... } else { ... }` block. Keep **only** the content from inside the `if` branch (the `ScrollView` with `LazyVStack` of `DialogRow`s). Delete the `else { ConditionalScriptsEditorView(...) }` branch and the `if/else` wrapper itself.

After this step: `CenterMode` has zero remaining references in `ScriptView.swift`. The center column shows only the dialog `ScrollView`.

- [ ] **Step 2: Add `showConditionals` state and sheet**

Add a new state property alongside the other `@State` declarations at the top of the struct body:

```swift
@State private var showConditionals = false
```

Add the sheet modifier on the outermost view (after the existing `.navigationTitle` modifier):

```swift
.sheet(isPresented: $showConditionals) {
    ConditionalScriptsEditorView(
        conditions: $conditionalScripts,
        availableScriptNames: availableScriptNames
    )
    .frame(minWidth: 800, minHeight: 500)
}
```

- [ ] **Step 3: Replace toolbar `ToolbarItem` with `ToolbarItemGroup`**

Find the existing `.toolbar` modifier. It contains:

```swift
ToolbarItem(placement: .primaryAction) {
    Button("Save") {
        var updatedScript = script
        updatedScript.update(with: self)
        script = updatedScript
        dismiss()
    }
}
```

Replace with a `ToolbarItemGroup` wrapping both buttons:

```swift
ToolbarItemGroup(placement: .primaryAction) {
    Button("Condicionales (\(conditionalScripts.count))") {
        showConditionals = true
    }
    Button("Save") {
        var updatedScript = script
        updatedScript.update(with: self)
        script = updatedScript
        dismiss()
    }
}
```

The Save button body is copied verbatim — do not change it.

- [ ] **Step 4: Build to verify no compile errors**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add LevelGenerator/Views/ScriptView.swift
git commit -m "feat: move conditionals to sheet, simplify ScriptView center column"
```

---

## Task 4: Refactor `ConditionalScriptsEditorView` + `ConditionalScriptRowView`

**Files:**
- Modify: `LevelGenerator/Views/ConditionalScriptsEditorView.swift`

`CenterMode` has no usages left after Task 3. It is now safe to delete it.

- [ ] **Step 1: Delete `CenterMode` enum**

At the very top of `ConditionalScriptsEditorView.swift`, delete:

```swift
// Modo del panel central en ScriptView
enum CenterMode {
    case dialogs
    case conditions
}
```

(These are lines 3–7, but use the enum declaration itself as the landmark, not the line numbers — prior edits may shift lines.)

- [ ] **Step 2: Add `@Environment(\.dismiss)` and "Cerrar" button**

In `struct ConditionalScriptsEditorView`, add at the top of the struct body (before `var body`):

```swift
@Environment(\.dismiss) var dismiss
```

In the header `HStack` (the one containing the title/subtitle `VStack`, `Spacer()`, and the "Agregar condición" `Button`), add a "Cerrar" button **after** the existing "Agregar condición" button:

```swift
Button("Cerrar") { dismiss() }
    .buttonStyle(.bordered)
```

The final header `HStack` will contain: title `VStack` → `Spacer()` → `Button(Agregar condición)` → `Button(Cerrar)`.

- [ ] **Step 3: Replace the script-destino field in `ConditionalScriptRowView`**

In `ConditionalScriptRowView`, find the `VStack(alignment: .leading, spacing: 2)` that contains:
- `TextField("Script", text: $condition.scriptName)`
- The `if !condition.scriptName.isEmpty, !availableScriptNames.isEmpty, ...` warning label

Replace the **entire `VStack`** with:

```swift
if availableScriptNames.isEmpty {
    VStack(alignment: .leading, spacing: 2) {
        TextField("Script", text: $condition.scriptName)
            .textFieldStyle(.roundedBorder)
            .frame(width: 145)
        Text("Cargá un archivo LDtk para usar autocompletado")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
} else {
    // condition is @Binding — direct mutation via Button closures is valid
    Menu(condition.scriptName.isEmpty ? "Seleccionar script" : condition.scriptName) {
        ForEach(availableScriptNames, id: \.self) { name in
            Button(name) { condition.scriptName = name }
        }
    }
    .frame(width: 145)
}
```

- [ ] **Step 4: Build to verify no compile errors**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add LevelGenerator/Views/ConditionalScriptsEditorView.swift
git commit -m "feat: add dismiss button and script name picker to conditionals editor"
```

---

## Task 5: Update `MacContentView`

**Files:**
- Modify: `LevelGenerator/Views/macOS/MacContentView.swift`

- [ ] **Step 1: Update `availableScriptNames` call-site**

Find the `ScriptView(script: ..., availableScriptNames: contentStore.scripts.map { $0.name })` instantiation (around line 127–130). Change:

```swift
availableScriptNames: contentStore.scripts.map { $0.name }
```

to:

```swift
availableScriptNames: contentStore.ldtkScriptNames
```

- [ ] **Step 2: Add error alert state properties**

Add three `@State` properties alongside the existing ones (after `scriptIdToDelete`):

```swift
@State private var showingLDtkFilePicker = false
@State private var showingLDtkErrorAlert = false
@State private var ldtkErrorMessage = ""
```

- [ ] **Step 3: Add "Cargar LDtk…" button to the toolbar**

In the existing `ToolbarItemGroup` block (inside the `content:` closure's `.toolbar`), add the button **before** the `Menu { Export/Import }` entry, wrapped in a `selectedSection == .scripts` check:

```swift
if selectedSection == .scripts {
    Button {
        showingLDtkFilePicker = true
    } label: {
        Label("Cargar LDtk…", systemImage: "doc.badge.arrow.up")
    }
}
```

- [ ] **Step 4: Add `.fileImporter` and error alert**

Add these modifiers alongside the existing `.sheet` and `.alert` modifiers (before the final closing `}` of the `NavigationSplitView`):

```swift
.fileImporter(
    isPresented: $showingLDtkFilePicker,
    allowedContentTypes: [.json]
) { result in
    switch result {
    case .success(let url):
        do {
            try contentStore.loadLDtkNames(from: url)
        } catch {
            ldtkErrorMessage = error.localizedDescription
            showingLDtkErrorAlert = true
        }
    case .failure(let error):
        ldtkErrorMessage = error.localizedDescription
        showingLDtkErrorAlert = true
    }
}
.alert("Error al cargar LDtk", isPresented: $showingLDtkErrorAlert) {
    Button("OK") {}
} message: {
    Text(ldtkErrorMessage)
}
```

- [ ] **Step 5: Wrap the `List` in `VStack` and add status label**

In the `content:` closure, find the `List(selection: ...) { ... }` block. It currently has `.navigationTitle` and `.toolbar` chained to it. Move these modifiers to the outer `VStack` — in `NavigationSplitView`'s content column, these modifiers must be on the **outermost** view to propagate correctly.

Replace:

```swift
List(selection: ...) {
    // ...existing contents...
}
.navigationTitle(selectedSection == .levels ? "Levels" : "Scripts")
.toolbar { /* existing */ }
```

With:

```swift
VStack(spacing: 0) {
    List(selection: selectedSection == .levels ? $selectedLevelId : $selectedScriptId) {
        // ...existing contents unchanged...
    }
    .frame(maxHeight: .infinity)

    if selectedSection == .scripts, let name = contentStore.ldtkFileName {
        Text("\(name) · \(contentStore.ldtkScriptNames.count) scripts")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
.navigationTitle(selectedSection == .levels ? "Levels" : "Scripts")
.toolbar {
    // ...existing toolbar contents unchanged...
}
```

- [ ] **Step 6: Build to verify no compile errors**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
git add LevelGenerator/Views/macOS/MacContentView.swift
git commit -m "feat: add LDtk file loader and status label to MacContentView"
```

---

## Task 6: Update `ContentListView` (iOS)

**Files:**
- Modify: `LevelGenerator/Views/Main/ContentListView.swift`

- [ ] **Step 1: Update `availableScriptNames` call-site**

Find the `ScriptView(script: ..., availableScriptNames: contentStore.scripts.map { $0.name })` instantiation inside the `#if os(iOS)` block (around line 49–52). Change:

```swift
availableScriptNames: contentStore.scripts.map { $0.name }
```

to:

```swift
availableScriptNames: contentStore.ldtkScriptNames
```

- [ ] **Step 2: Add `@State` properties for the file importer**

Add these three `@State` properties alongside the existing `showingConnectionMap` property. Place them **outside** any `#if os(iOS)` guard (they're harmless on macOS and this avoids conditional-compilation complexity):

```swift
@State private var showingLDtkFilePicker = false
@State private var showingLDtkErrorAlert = false
@State private var ldtkErrorMessage = ""
```

- [ ] **Step 3: Add "Cargar LDtk…" toolbar button + fileImporter + alert (iOS only)**

The existing `ContentListView` file ends with:

```swift
    #if os(iOS)
    .toolbar {
        ToolbarItem(placement: .primaryAction) { ... }  // existing Add button
        ToolbarItem(placement: .primaryAction) { ... }  // existing More menu
    }
    #endif
}  // end of body
```

Replace the entire `#if os(iOS) ... #endif` block with a single expanded block that includes the new button and the file importer:

```swift
#if os(iOS)
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        // existing Add button — unchanged
        Button {
            if selectedSection == .levels {
                showingNewLevelSheet = true
            } else {
                showingNewScriptSheet = true
            }
        } label: {
            Image(systemName: "plus")
        }
    }

    ToolbarItem(placement: .primaryAction) {
        // existing More menu — unchanged
        Menu {
            Button { showingExportSheet = true } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            Button { showingImportSheet = true } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    if selectedSection == .scripts {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingLDtkFilePicker = true
            } label: {
                Image(systemName: "doc.badge.arrow.up")
            }
        }
    }
}
.fileImporter(
    isPresented: $showingLDtkFilePicker,
    allowedContentTypes: [.json]
) { result in
    switch result {
    case .success(let url):
        do {
            try contentStore.loadLDtkNames(from: url)
        } catch {
            ldtkErrorMessage = error.localizedDescription
            showingLDtkErrorAlert = true
        }
    case .failure(let error):
        ldtkErrorMessage = error.localizedDescription
        showingLDtkErrorAlert = true
    }
}
.alert("Error al cargar LDtk", isPresented: $showingLDtkErrorAlert) {
    Button("OK") {}
} message: {
    Text(ldtkErrorMessage)
}
#endif
```

- [ ] **Step 5: Build for both platforms**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -5
xcodebuild build -scheme LevelGenerator -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED` for both.

- [ ] **Step 6: Run all tests**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -20
```

Expected: All tests pass.

- [ ] **Step 7: Final commit**

```bash
git add LevelGenerator/Views/Main/ContentListView.swift
git commit -m "feat: add LDtk file loader to iOS ContentListView"
```

---

## Validation Checklist

Manual smoke test after all tasks complete:

- [ ] Open the app on macOS. Scripts section visible in content column.
- [ ] "Cargar LDtk…" button appears in toolbar only when Scripts tab is selected.
- [ ] Load a `.json` file from the DinoPirates project. Status label appears: `"filename.json · N scripts"`.
- [ ] Open any script. Center column shows only the dialog list — no mode toggle visible.
- [ ] Toolbar shows "Condicionales (N)" and "Save" side by side.
- [ ] Tap "Condicionales (N)". Sheet opens at ≥800×500 pt with column headers visible.
- [ ] Each condition row's script-destino shows a `Menu` with script names from the loaded file.
- [ ] Select a name from the Menu. Preview string in the row updates immediately.
- [ ] Tap "Cerrar". Sheet dismisses. The count in the toolbar reflects any changes.
- [ ] Tap "Save". Left column shows the updated `conditionalScripts` Lua output.
- [ ] Without loading any file: open the conditionals sheet — script-destino shows `TextField` with caption.
- [ ] Relaunch the app. Previously loaded script names and filename persist (UserDefaults).
