# Trigger Model Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat `scripts` model with a `triggers` hierarchy where each trigger owns its scripts and conditionals, with sidebar-based navigation and per-script copy buttons.

**Architecture:** Add `SavedTrigger` and `SidebarItem` as new models, extend `ContentStore` with trigger-scoped CRUD, then rewrite the macOS and iOS view layers to consume the new hierarchy. Old data is discarded (fresh start). LDtk loading is removed entirely.

**Tech Stack:** Swift 5.9+, SwiftUI, Swift Testing (`import Testing`, `@Test`, `#expect`). macOS + iOS. No external dependencies.

---

## File Map

| Action | File | What changes |
|--------|------|-------------|
| Create | `LevelGenerator/Models/SidebarItem.swift` | New `SidebarItem` enum (`.levels`, `.trigger(UUID)`) |
| Create | `LevelGenerator/Models/ScriptLuaGenerator.swift` | Pure Lua/localization generator extracted from `ScriptView` |
| Create | `LevelGeneratorTests/ScriptLuaGeneratorTests.swift` | Tests for `ScriptLuaGenerator` |
| Modify | `LevelGenerator/Models/SavedContent.swift` | Add `SavedTrigger`; add trigger CRUD to `ContentStore`; strip old in Task 5 |
| Create | `LevelGeneratorTests/ContentStoreTriggerTests.swift` | Tests for trigger CRUD |
| Modify | `LevelGenerator/Models/ContentSection.swift` | Delete `ContentSection`, replace with `typealias` import note (then delete file in Task 3) |
| Modify | `LevelGenerator/Views/ScriptView.swift` | Strip all conditional code; use `ScriptLuaGenerator` |
| Modify | `LevelGenerator/Views/Main/ContentManagerView.swift` | Use `SidebarItem` binding; remove `showingNewScriptSheet` |
| Modify | `LevelGenerator/Views/macOS/MacContentView.swift` | Full rewrite: trigger sidebar, per-trigger content column |
| Create | `LevelGenerator/Views/Sheets/NewTriggerSheet.swift` | New trigger creation sheet |
| Create | `LevelGenerator/Views/Sheets/NewScriptInTriggerSheet.swift` | New script-in-trigger creation sheet |
| Create | `LevelGenerator/Views/Components/ScriptRowWithCopyButtons.swift` | Row view with Lua + Strings copy buttons |
| Modify | `LevelGenerator/Views/iOS/iOSContentView.swift` | Use `SidebarItem`; remove `showingNewScriptSheet` |
| Modify | `LevelGenerator/Views/Main/ContentListView.swift` | Triggers tab: list all triggers → NavigationLink → TriggerScriptsView |
| Create | `LevelGenerator/Views/Main/TriggerScriptsView.swift` | iOS: scripts within a trigger |
| Delete | `LevelGenerator/Models/ContentSection.swift` | Replaced by `SidebarItem.swift` |
| Delete | `LevelGenerator/Views/Sheets/NewScriptSheet.swift` | Replaced by `NewTriggerSheet` + `NewScriptInTriggerSheet` |
| Delete | `LevelGenerator/Parsers/LDtkScriptNameExtractor.swift` | No longer needed |
| Delete | `LevelGeneratorTests/LDtkScriptNameExtractorTests.swift` | No longer needed |

**Task order matters:**
- Task 1 and 2 are pure additions — nothing breaks
- Task 3 switches macOS views and ScriptView (also fixes `SavedScript.update(with:)`)
- Task 4 switches iOS views
- Task 5 removes all dead code — must come last

---

## Task 1: `SidebarItem` + `ScriptLuaGenerator` (TDD)

**Files:**
- Create: `LevelGenerator/Models/SidebarItem.swift`
- Create: `LevelGenerator/Models/ScriptLuaGenerator.swift`
- Create: `LevelGeneratorTests/ScriptLuaGeneratorTests.swift`

- [ ] **Step 1: Create `SidebarItem.swift`**

```swift
import Foundation

enum SidebarItem: Hashable {
    case levels
    case trigger(UUID)
}
```

- [ ] **Step 2: Write failing tests for `ScriptLuaGenerator`**

Create `LevelGeneratorTests/ScriptLuaGeneratorTests.swift`:

```swift
import Testing
@testable import LevelGenerator

struct ScriptLuaGeneratorTests {

    @Test func lua_containsNameAndDialogKey() throws {
        let script = SavedScript(name: "big", dialogs: [
            SavedScript.SavedDialog(image: "player", text: "Hello", key: "big-01")
        ])
        let result = ScriptLuaGenerator.lua(for: script)
        #expect(result.contains("name = \"big\""))
        #expect(result.contains("text = \"big-01\""))
        #expect(result.contains("video = 'player'"))
    }

    @Test func lua_emptyDialogs_stillContainsName() throws {
        let script = SavedScript(name: "empty")
        let result = ScriptLuaGenerator.lua(for: script)
        #expect(result.contains("name = \"empty\""))
    }

    @Test func localization_formatsKeyValuePair() throws {
        let script = SavedScript(name: "big", dialogs: [
            SavedScript.SavedDialog(image: "player", text: "Hello world", key: "big-01")
        ])
        let result = ScriptLuaGenerator.localization(for: script)
        #expect(result == "\"big-01\" = \"Hello world\"")
    }

    @Test func localization_multipleDialogs_joinedWithDoubleNewline() throws {
        let script = SavedScript(name: "big", dialogs: [
            SavedScript.SavedDialog(image: "player", text: "Line 1", key: "big-01"),
            SavedScript.SavedDialog(image: "player", text: "Line 2", key: "big-02")
        ])
        let result = ScriptLuaGenerator.localization(for: script)
        #expect(result.contains("\"big-01\" = \"Line 1\""))
        #expect(result.contains("\"big-02\" = \"Line 2\""))
        #expect(result.contains("\n\n"))
    }

    @Test func localization_emptyDialogs_returnsEmptyString() throws {
        let script = SavedScript(name: "empty")
        let result = ScriptLuaGenerator.localization(for: script)
        #expect(result.isEmpty)
    }
}
```

- [ ] **Step 3: Run tests — expect FAIL (type doesn't exist yet)**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' -only-testing:LevelGeneratorTests/ScriptLuaGeneratorTests 2>&1 | tail -5
```

Expected: compiler error.

- [ ] **Step 4: Create `ScriptLuaGenerator.swift`**

```swift
import Foundation

enum ScriptLuaGenerator {

    /// Generates the Lua table block for a script's dialog array.
    static func lua(for script: SavedScript) -> String {
        """
        {
            name = "\(script.name)",
            dialog = {
                \(script.dialogs.map { dialog in
                    """
                    {
                        video = '\(dialog.image)',
                        text = "\(dialog.key)",
                    }
                    """
                }.joined(separator: ",\n                "))

            }
        },
        """
    }

    /// Generates the .strings localization block for a script's dialogs.
    static func localization(for script: SavedScript) -> String {
        script.dialogs.map { dialog in
            """
            "\(dialog.key)" = "\(dialog.text)"
            """
        }.joined(separator: "\n\n")
    }
}
```

- [ ] **Step 5: Run tests — expect PASS**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' -only-testing:LevelGeneratorTests/ScriptLuaGeneratorTests 2>&1 | tail -10
```

Expected: 5 tests pass.

- [ ] **Step 6: Build to verify nothing broke**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
git add LevelGenerator/Models/SidebarItem.swift LevelGenerator/Models/ScriptLuaGenerator.swift LevelGeneratorTests/ScriptLuaGeneratorTests.swift
git commit -m "feat: add SidebarItem enum and ScriptLuaGenerator helper"
```

---

## Task 2: Add `SavedTrigger` + extend `ContentStore`

**Files:**
- Modify: `LevelGenerator/Models/SavedContent.swift`
- Create: `LevelGeneratorTests/ContentStoreTriggerTests.swift`

This task is purely additive — old `scripts` and old methods stay unchanged. Nothing breaks.

- [ ] **Step 1: Write failing tests**

Create `LevelGeneratorTests/ContentStoreTriggerTests.swift`:

```swift
import Testing
@testable import LevelGenerator

struct ContentStoreTriggerTests {

    // Helper: fresh store with no persisted data
    private func freshStore() -> ContentStore {
        UserDefaults.standard.removeObject(forKey: "savedTriggers")
        return ContentStore()
    }

    @Test func addTrigger_appendsTrigger() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp"))
        #expect(store.triggers.count == 1)
        #expect(store.triggers[0].name == "lamp")
    }

    @Test func deleteTrigger_removesTrigger() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp"))
        store.deleteTrigger(at: IndexSet([0]))
        #expect(store.triggers.isEmpty)
    }

    @Test func addScript_addsToCorrectTrigger() {
        let store = freshStore()
        let trigger = SavedTrigger(name: "lamp")
        store.addTrigger(trigger)
        store.addScript(SavedScript(name: "big"), to: trigger.id)
        #expect(store.triggers[0].scripts.count == 1)
        #expect(store.triggers[0].scripts[0].name == "big")
    }

    @Test func addScript_doesNothingForUnknownTriggerId() {
        let store = freshStore()
        store.addScript(SavedScript(name: "big"), to: UUID())
        #expect(store.triggers.isEmpty)
    }

    @Test func deleteScript_removesFromTrigger() {
        let store = freshStore()
        let trigger = SavedTrigger(name: "lamp")
        store.addTrigger(trigger)
        let script = SavedScript(name: "big")
        store.addScript(script, to: trigger.id)
        store.deleteScript(scriptId: script.id, from: trigger.id)
        #expect(store.triggers[0].scripts.isEmpty)
    }

    @Test func scriptBinding_returnsCorrectScript() {
        let store = freshStore()
        let trigger = SavedTrigger(name: "lamp")
        store.addTrigger(trigger)
        let script = SavedScript(name: "big")
        store.addScript(script, to: trigger.id)
        let binding = store.scriptBinding(triggerId: trigger.id, scriptId: script.id)
        #expect(binding.wrappedValue.name == "big")
    }

    @Test func triggerBinding_returnsCorrectTrigger() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp"))
        let id = store.triggers[0].id
        let binding = store.triggerBinding(id: id)
        #expect(binding.wrappedValue.name == "lamp")
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' -only-testing:LevelGeneratorTests/ContentStoreTriggerTests 2>&1 | tail -5
```

Expected: compiler error — `SavedTrigger` not found.

- [ ] **Step 3: Add `SavedTrigger` struct to `SavedContent.swift`**

Insert after the closing `}` of `SavedScript` (before `TriggerScriptInfo`):

```swift
// MARK: - Trigger guardado

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

- [ ] **Step 4: Add `triggers` property and key to `ContentStore`**

In `ContentStore`, after `@Published var scripts: [SavedScript] = []`, add:

```swift
@Published var triggers: [SavedTrigger] = []
private let triggersKey = "savedTriggers"
```

- [ ] **Step 5: Load and save triggers in `loadContent()` / `saveContent()`**

In `loadContent()`, add after the existing scripts-loading block:

```swift
if let triggersData = UserDefaults.standard.data(forKey: triggersKey),
   let decodedTriggers = try? JSONDecoder().decode([SavedTrigger].self, from: triggersData) {
    triggers = decodedTriggers
}
```

In `saveContent()`, add after the existing scripts-saving block:

```swift
if let encodedTriggers = try? JSONEncoder().encode(triggers) {
    UserDefaults.standard.set(encodedTriggers, forKey: triggersKey)
}
```

- [ ] **Step 6: Add trigger CRUD methods**

Add after `deleteScript(at:)`:

```swift
func addTrigger(_ trigger: SavedTrigger) {
    triggers.append(trigger)
    saveContent()
}

func updateTrigger(at index: Int, with trigger: SavedTrigger) {
    triggers[index] = trigger
    saveContent()
}

func deleteTrigger(at offsets: IndexSet) {
    triggers.remove(atOffsets: offsets)
    saveContent()
}

func addScript(_ script: SavedScript, to triggerId: UUID) {
    guard let i = triggers.firstIndex(where: { $0.id == triggerId }) else { return }
    triggers[i].scripts.append(script)
    saveContent()
}

func deleteScript(scriptId: UUID, from triggerId: UUID) {
    guard let ti = triggers.firstIndex(where: { $0.id == triggerId }),
          let si = triggers[ti].scripts.firstIndex(where: { $0.id == scriptId })
    else { return }
    triggers[ti].scripts.remove(at: si)
    saveContent()
}
```

- [ ] **Step 7: Add trigger and script bindings**

Add to the `extension ContentStore` block that already has `scriptBinding(id:)`:

```swift
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

- [ ] **Step 8: Run tests — expect PASS**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' -only-testing:LevelGeneratorTests/ContentStoreTriggerTests 2>&1 | tail -10
```

Expected: 7 tests pass.

- [ ] **Step 9: Full build to verify nothing broke**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 10: Commit**

```bash
git add LevelGenerator/Models/SavedContent.swift LevelGeneratorTests/ContentStoreTriggerTests.swift
git commit -m "feat: add SavedTrigger and trigger CRUD to ContentStore"
```

---

## Task 3: macOS view layer + `ScriptView` simplification

**Files:**
- Modify: `LevelGenerator/Models/ContentSection.swift` → delete and replace with `SidebarItem` contents
- Modify: `LevelGenerator/Views/Main/ContentManagerView.swift`
- Modify: `LevelGenerator/Views/macOS/MacContentView.swift`
- Modify: `LevelGenerator/Views/ScriptView.swift`
- Modify: `LevelGenerator/Models/SavedContent.swift` (remove one line from `SavedScript.update(with:)`)
- Create: `LevelGenerator/Views/Sheets/NewTriggerSheet.swift`
- Create: `LevelGenerator/Views/Sheets/NewScriptInTriggerSheet.swift`
- Create: `LevelGenerator/Views/Components/ScriptRowWithCopyButtons.swift`

This task switches the macOS navigation to `SidebarItem` and rewrites `MacContentView`. It also simplifies `ScriptView`. At the end the build succeeds.

- [ ] **Step 1: Replace `ContentSection.swift` with `SidebarItem`**

`ContentSection.swift` currently holds `enum ContentSection { case levels, scripts }`. Replace the entire file contents:

```swift
import Foundation

// ContentSection replaced by SidebarItem
// (kept as file to avoid pbxproj changes — file content is now SidebarItem)
// If ContentSection references remain elsewhere, they will produce compile errors
// that must be fixed in the same task.
```

Wait — actually delete and recreate the file with just the typealias deleted. Since `SidebarItem.swift` already exists from Task 1, the cleanest approach is to delete `ContentSection.swift` entirely and update all references to `ContentSection` in the same step.

**Replace entire contents of `ContentSection.swift`** with an empty file keeping the import:

```swift
// This file intentionally empty — SidebarItem replaces ContentSection.
// See SidebarItem.swift
```

This removes the `ContentSection` type. Any file still referencing `ContentSection` will now fail to compile — fix those in the following steps.

- [ ] **Step 2: Update `ContentManagerView.swift`**

Replace the entire file:

```swift
import SwiftUI

struct ContentManagerView: View {
    @StateObject private var contentStore = ContentStore()
    @State private var selectedSidebarItem: SidebarItem = .levels
    @State private var showingNewLevelSheet = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var importText = ""
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""

    var body: some View {
        NavigationStack {
            #if os(iOS)
            iOSContentView(
                contentStore: contentStore,
                selectedSidebarItem: $selectedSidebarItem,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet,
                importText: $importText,
                showingImportAlert: $showingImportAlert,
                importAlertMessage: $importAlertMessage
            )
            .toolbar {
                if case .levels = selectedSidebarItem {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink {
                            RoomConnectionMapView(levels: contentStore.levels, contentStore: contentStore)
                                .navigationTitle("Room Connections")
                        } label: {
                            Label("View Connections", systemImage: "map")
                        }
                    }
                }
            }
            #else
            MacContentView(
                contentStore: contentStore,
                selectedSidebarItem: $selectedSidebarItem,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet,
                importText: $importText,
                showingImportAlert: $showingImportAlert,
                importAlertMessage: $importAlertMessage
            )
            .toolbar {
                if case .levels = selectedSidebarItem {
                    ToolbarItem(placement: .automatic) {
                        NavigationLink {
                            RoomConnectionMapView(levels: contentStore.levels, contentStore: contentStore)
                                .navigationTitle("Room Connections")
                        } label: {
                            Label("View Connections", systemImage: "map")
                        }
                    }
                }
            }
            #endif
        }
        .preferredColorScheme(.light)
    }
}
```

- [ ] **Step 3: Rewrite `MacContentView.swift`**

Replace the entire file:

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
    @State private var selectedScriptId: UUID?
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var showConditionals = false
    @State private var showingNewTriggerSheet = false
    @State private var showingNewScriptSheet = false
    @State private var showingDeleteAlert = false
    @State private var deletingScriptId: UUID?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // ── Sidebar ───────────────────────────────────────────────────
            List(selection: $selectedSidebarItem) {
                NavigationLink(value: SidebarItem.levels) {
                    Label("Levels", systemImage: "square.stack.3d.up")
                }
                Section("Triggers") {
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
                            } label: {
                                Label("Delete Trigger", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Content")
            .listStyle(.sidebar)
            .toolbar {
                Button {
                    if case .levels = selectedSidebarItem {
                        showingNewLevelSheet = true
                    } else {
                        showingNewTriggerSheet = true
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }

        } content: {
            // ── Content column ────────────────────────────────────────────
            if case .trigger(let triggerId) = selectedSidebarItem,
               contentStore.triggers.contains(where: { $0.id == triggerId }) {

                let trigger = contentStore.triggerBinding(id: triggerId)

                VStack(spacing: 0) {
                    List(selection: $selectedScriptId) {
                        ForEach(trigger.wrappedValue.scripts) { script in
                            NavigationLink(value: script.id) {
                                ScriptRowWithCopyButtons(script: script)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deletingScriptId = script.id
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Script", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { offsets in
                            offsets.forEach { i in
                                let id = trigger.wrappedValue.scripts[i].id
                                contentStore.deleteScript(scriptId: id, from: triggerId)
                            }
                            selectedScriptId = nil
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .navigationTitle(trigger.wrappedValue.name)
                .toolbar {
                    ToolbarItemGroup {
                        Button {
                            showingNewScriptSheet = true
                        } label: {
                            Label("Add Script", systemImage: "plus")
                        }

                        if selectedScriptId != nil {
                            Button(role: .destructive) {
                                deletingScriptId = selectedScriptId
                                showingDeleteAlert = true
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
                        } label: {
                            Label("More", systemImage: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showConditionals) {
                    ConditionalScriptsEditorView(
                        conditions: $trigger.conditionalScripts,
                        availableScriptNames: trigger.wrappedValue.scripts.map { $0.name }
                    )
                    .frame(minWidth: 800, minHeight: 500)
                }
                .sheet(isPresented: $showingNewScriptSheet) {
                    NewScriptInTriggerSheet { name in
                        contentStore.addScript(SavedScript(name: name), to: triggerId)
                    }
                }
                .alert("Delete Script", isPresented: $showingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        if let id = deletingScriptId {
                            contentStore.deleteScript(scriptId: id, from: triggerId)
                            if selectedScriptId == id { selectedScriptId = nil }
                        }
                        deletingScriptId = nil
                    }
                    Button("Cancel", role: .cancel) { deletingScriptId = nil }
                } message: {
                    Text("This action cannot be undone.")
                }

            } else {
                // Levels list
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
                .toolbar {
                    ToolbarItemGroup {
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

        } detail: {
            // ── Detail column ─────────────────────────────────────────────
            Group {
                if case .levels = selectedSidebarItem {
                    if let selectedId = selectedLevelId,
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
                } else if case .trigger(let triggerId) = selectedSidebarItem {
                    if let selectedId = selectedScriptId,
                       let ti = contentStore.triggers.firstIndex(where: { $0.id == triggerId }),
                       contentStore.triggers[ti].scripts.contains(where: { $0.id == selectedId }) {
                        ScriptView(script: contentStore.scriptBinding(triggerId: triggerId, scriptId: selectedId))
                            .id(selectedId)
                    } else {
                        ContentUnavailableView {
                            Label("No Script Selected", systemImage: "doc.text")
                        } description: {
                            Text("Select a script from the list to edit it")
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Select a Trigger", systemImage: "text.word.spacing")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingNewLevelSheet) {
            NewLevelSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewTriggerSheet) {
            NewTriggerSheet(contentStore: contentStore)
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
}
#endif
```

- [ ] **Step 4: Create `NewTriggerSheet.swift`**

```swift
import SwiftUI

struct NewTriggerSheet: View {
    @ObservedObject var contentStore: ContentStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Trigger")
                .font(.headline)
            TextField("Trigger name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    contentStore.addTrigger(SavedTrigger(name: name))
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

- [ ] **Step 5: Create `NewScriptInTriggerSheet.swift`**

```swift
import SwiftUI

struct NewScriptInTriggerSheet: View {
    @Environment(\.dismiss) var dismiss
    var onConfirm: (String) -> Void
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Script")
                .font(.headline)
            TextField("Script name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Button("Create") {
                    onConfirm(name)
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

- [ ] **Step 6: Create `ScriptRowWithCopyButtons.swift`**

```swift
import SwiftUI

struct ScriptRowWithCopyButtons: View {
    let script: SavedScript

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(script.name)
                    .font(.headline)
                Text("\(script.dialogs.count) dialogs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Lua") { copy(ScriptLuaGenerator.lua(for: script)) }
                .buttonStyle(.bordered)
            Button("Strings") { copy(ScriptLuaGenerator.localization(for: script)) }
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }

    private func copy(_ string: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #else
        UIPasteboard.general.string = string
        #endif
    }
}
```

- [ ] **Step 7: Simplify `ScriptView.swift`**

Replace the entire file. Key changes from current version:
- Remove `availableScriptNames` parameter
- Remove `@State private var conditionalScripts`
- Remove `@State private var showConditionals`
- Remove `var scriptConditionalScripts` computed property
- Remove `var generatedConditionalScripts` computed property
- Remove "Conditional Scripts" GroupBox from left column
- Remove `.sheet(isPresented: $showConditionals)` block
- Remove "Condicionales" Button from toolbar
- Replace inline `generatedLuaScript`/`generatedLocalization` with `ScriptLuaGenerator`
- Update `init` signature

```swift
import SwiftUI

struct ScriptView: View {
    @Binding var script: SavedScript
    @Environment(\.dismiss) var dismiss

    @State private var selectedImage: String = "player"
    @State private var currentDialog: String = ""
    @State private var currentName: String
    @State private var dialogs: [(image: String, text: String, key: String)]

    let availableImages = [
        "player", "playerWorry", "playerSurprise",
        "radioHand", "radioPocket", "radioRing",
        "notesHand", "playerHappy", "playerAngry", "playerSleepy", "playerCry"
    ]

    // Propiedades públicas para SavedScript.update(with:)
    var scriptName: String { currentName }
    var scriptDialogs: [(image: String, text: String, key: String)] { dialogs }

    init(script: Binding<SavedScript>) {
        self._script = script
        _currentName = State(initialValue: script.wrappedValue.name)
        _dialogs = State(initialValue: script.wrappedValue.dialogs.map { dialog in
            (image: dialog.image, text: dialog.text, key: dialog.key)
        })
    }

    // MARK: - Computed: key generation

    private func generateScriptKey() -> String {
        let formattedName = currentName.lowercased().replacingOccurrences(of: " ", with: "-")
        let dialogCount = dialogs.filter { $0.key.starts(with: formattedName) }.count + 1
        let numberString = String(format: "%02d", dialogCount)
        return "\(formattedName)-\(numberString)"
    }

    // MARK: - Computed: outputs via ScriptLuaGenerator

    var generatedLuaScript: String {
        let tempScript = SavedScript(
            name: currentName,
            dialogs: dialogs.map { SavedScript.SavedDialog(image: $0.image, text: $0.text, key: $0.key) }
        )
        return ScriptLuaGenerator.lua(for: tempScript)
    }

    var generatedLocalization: String {
        let tempScript = SavedScript(
            name: currentName,
            dialogs: dialogs.map { SavedScript.SavedDialog(image: $0.image, text: $0.text, key: $0.key) }
        )
        return ScriptLuaGenerator.localization(for: tempScript)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {

            // ── Left Column: outputs ──────────────────────────────────────
            ScrollView {
                VStack(spacing: 12) {

                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Generated Lua Script")
                                    .font(.headline)
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
                                Text("Generated Localization")
                                    .font(.headline)
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

            // ── Center Column: diálogos ───────────────────────────────────
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(dialogs.enumerated()), id: \.offset) { index, dialog in
                            DialogRow(
                                image: dialog.image,
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

            // ── Right Column: input de diálogo ────────────────────────────
            VStack(spacing: 16) {

                GroupBox("Select Character") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.fixed(110))], spacing: 8) {
                            ForEach(availableImages, id: \.self) { image in
                                Button {
                                    selectedImage = image
                                } label: {
                                    Image(image)
                                        .resizable()
                                        .frame(width: 118, height: 94)
                                        .padding(8)
                                        .background(selectedImage == image ? Color.blue.opacity(0.2) : Color.clear)
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
                        set: { newValue in
                            if newValue.count <= 94 { currentDialog = newValue }
                        }
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

                Button {
                    if !currentDialog.isEmpty && !currentName.isEmpty {
                        dialogs.append((
                            image: selectedImage,
                            text: currentDialog,
                            key: generateScriptKey()
                        ))
                        currentDialog = ""
                    }
                } label: {
                    Text("Add Dialog")
                        .frame(maxWidth: .infinity)
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
                    var updatedScript = script
                    updatedScript.update(with: self)
                    script = updatedScript
                    dismiss()
                }
            }
        }
    }
}
```

- [ ] **Step 8: Fix `SavedScript.update(with:)` in `SavedContent.swift`**

In `SavedContent.swift`, find `mutating func update(with scriptView: ScriptView)` inside `SavedScript`. Delete the line:

```swift
conditionalScripts = scriptView.scriptConditionalScripts
```

After this change, `update(with:)` only updates `name` and `dialogs`.

- [ ] **Step 9: Build to verify**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`. Fix any remaining `ContentSection` references if they appear.

- [ ] **Step 10: Commit**

```bash
git add LevelGenerator/Models/ContentSection.swift \
        LevelGenerator/Views/Main/ContentManagerView.swift \
        LevelGenerator/Views/macOS/MacContentView.swift \
        LevelGenerator/Views/ScriptView.swift \
        LevelGenerator/Models/SavedContent.swift \
        LevelGenerator/Views/Sheets/NewTriggerSheet.swift \
        LevelGenerator/Views/Sheets/NewScriptInTriggerSheet.swift \
        LevelGenerator/Views/Components/ScriptRowWithCopyButtons.swift
git commit -m "feat: rewrite macOS view layer for trigger hierarchy"
```

---

## Task 4: iOS view layer

**Files:**
- Modify: `LevelGenerator/Views/iOS/iOSContentView.swift`
- Modify: `LevelGenerator/Views/Main/ContentListView.swift`
- Create: `LevelGenerator/Views/Main/TriggerScriptsView.swift`

- [ ] **Step 1: Create `TriggerScriptsView.swift`**

```swift
import SwiftUI

struct TriggerScriptsView: View {
    @Binding var trigger: SavedTrigger
    @ObservedObject var contentStore: ContentStore
    @State private var showConditionals = false
    @State private var showingNewScriptSheet = false

    var body: some View {
        List {
            ForEach(trigger.scripts) { script in
                NavigationLink {
                    ScriptView(script: contentStore.scriptBinding(triggerId: trigger.id, scriptId: script.id))
                } label: {
                    ScriptRowWithCopyButtons(script: script)
                }
            }
            .onDelete { offsets in
                offsets.forEach { i in
                    let id = trigger.scripts[i].id
                    contentStore.deleteScript(scriptId: id, from: trigger.id)
                }
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
            NavigationStack {
                NewScriptInTriggerSheet { name in
                    contentStore.addScript(SavedScript(name: name), to: trigger.id)
                }
            }
        }
    }
}
```

Note: `$trigger.conditionalScripts` works because `trigger` is `@Binding var trigger: SavedTrigger`. SwiftUI's dynamic member lookup on `Binding` gives `Binding<[ConditionalScript]>`.

- [ ] **Step 2: Rewrite `iOSContentView.swift`**

Replace the entire file:

```swift
#if os(iOS)
import SwiftUI

struct iOSContentView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var importText: String
    @Binding var showingImportAlert: Bool
    @Binding var importAlertMessage: String

    var body: some View {
        NavigationStack {
            ContentListView(
                contentStore: contentStore,
                selectedSidebarItem: $selectedSidebarItem,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet,
                selectedLevel: .constant(nil)
            )
        }
        .sheet(isPresented: $showingNewLevelSheet) {
            NavigationStack {
                NewLevelSheet(contentStore: contentStore)
            }
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
}
#endif
```

- [ ] **Step 3: Rewrite `ContentListView.swift`**

Replace the entire file:

```swift
import SwiftUI

struct ContentListView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSidebarItem: SidebarItem
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var selectedLevel: SavedLevel?

    @State private var showTriggers = false
    @State private var showingNewTriggerSheet = false

    var body: some View {
        List {
            Picker("Section", selection: $showTriggers) {
                Text("Levels").tag(false)
                Text("Triggers").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)
            .onChange(of: showTriggers) { _, showing in
                if !showing { selectedSidebarItem = .levels }
            }

            if !showTriggers {
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
                .onDelete { indexSet in
                    contentStore.deleteLevel(at: indexSet)
                }
            } else {
                ForEach(contentStore.triggers) { trigger in
                    #if os(iOS)
                    NavigationLink {
                        TriggerScriptsView(
                            trigger: contentStore.triggerBinding(id: trigger.id),
                            contentStore: contentStore
                        )
                    } label: {
                        Text(trigger.name)
                            .font(.headline)
                    }
                    #else
                    Text(trigger.name)
                    #endif
                }
                .onDelete { offsets in
                    contentStore.deleteTrigger(at: offsets)
                }
            }
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if !showTriggers {
                        showingNewLevelSheet = true
                    } else {
                        showingNewTriggerSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
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
        }
        .sheet(isPresented: $showingNewTriggerSheet) {
            NavigationStack {
                NewTriggerSheet(contentStore: contentStore)
            }
        }
        #endif
    }
}
```

Note: `NewTriggerSheet` expects to be in a `NavigationStack` on iOS for its navigation toolbar items. On macOS the sheet doesn't need one since the view uses a plain `VStack`.

- [ ] **Step 4: Build both platforms**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -3
xcodebuild build -scheme LevelGenerator -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3
```

If `iPhone 16` is unavailable, try `iPhone 15` or run `xcrun simctl list devices` to find an available name.

Expected: `BUILD SUCCEEDED` for both.

- [ ] **Step 5: Commit**

```bash
git add LevelGenerator/Views/Main/TriggerScriptsView.swift \
        LevelGenerator/Views/iOS/iOSContentView.swift \
        LevelGenerator/Views/Main/ContentListView.swift
git commit -m "feat: rewrite iOS view layer for trigger hierarchy"
```

---

## Task 5: Final cleanup — remove dead code and LDtk

**Files:**
- Modify: `LevelGenerator/Models/SavedContent.swift` (remove old scripts, LDtk, `SavedScript.conditionalScripts`)
- Delete: `LevelGenerator/Models/ContentSection.swift` (already emptied in Task 3)
- Delete: `LevelGenerator/Views/Sheets/NewScriptSheet.swift`
- Delete: `LevelGenerator/Parsers/LDtkScriptNameExtractor.swift`
- Delete: `LevelGeneratorTests/LDtkScriptNameExtractorTests.swift`

- [ ] **Step 1: Remove `SavedScript.conditionalScripts` and related code**

In `SavedContent.swift`, in the `SavedScript` struct:

1. Delete `var conditionalScripts: [ConditionalScript]`
2. In `CodingKeys`: delete `case conditionalScripts`
3. In `init(id:name:dialogs:)`: remove `conditionalScripts: [ConditionalScript] = []` parameter and the body assignment
4. Delete the entire custom `init(from decoder: Decoder) throws` (backward-compat decoder — no longer needed with fresh start)

After these deletions, `SavedScript` has only `id`, `name`, `dialogs`, synthesized `Codable`, and `update(with:)`.

- [ ] **Step 2: Remove old `ContentStore.scripts` and related CRUD**

In `ContentStore`:
- Delete `@Published var scripts: [SavedScript] = []`
- Delete `private let scriptsKey = "savedScripts"`
- In `loadContent()`: delete the scripts-loading block
- In `saveContent()`: delete the scripts-saving block
- Delete `func addScript(_ script: SavedScript)` (the old flat-list version — not the `to triggerId:` one)
- Delete `func updateScript(at index: Int, with script: SavedScript)`
- Delete `func deleteScript(at offsets: IndexSet)` (the old flat-list version — not the `scriptId:from:` one)
- In the extension with `scriptBinding(id:)`: delete `func scriptBinding(id: UUID) -> Binding<SavedScript>` (the old flat-list version)
- Delete `func getTriggerScripts() -> [RoomScripts]` and the supporting structs `TriggerScriptInfo` and `RoomScripts`

- [ ] **Step 3: Remove LDtk from `ContentStore`**

In `ContentStore`:
- Delete `@Published var ldtkScriptNames: [String] = []`
- Delete `@Published var ldtkFileName: String? = nil`
- Delete `private let ldtkScriptNamesKey = "ldtkScriptNames"`
- Delete `private let ldtkFileNameKey = "ldtkFileName"`
- Delete the two UserDefaults lines in `init()` that load `ldtkScriptNames` and `ldtkFileName`
- Delete `func loadLDtkNames(from url: URL) throws`

- [ ] **Step 4: Update `ExportData` to use only triggers**

Replace the `ExportData` struct and its usages:

```swift
struct ExportData: Codable {
    let levels: [SavedLevel]
    let triggers: [SavedTrigger]
    let nodeStyles: [NodeStyle]
    let version: String

    init(levels: [SavedLevel], triggers: [SavedTrigger]) {
        self.levels = levels
        self.triggers = triggers
        self.nodeStyles = UserDefaults.standard.data(forKey: "nodeStyles")
            .flatMap { try? JSONDecoder().decode([NodeStyle].self, from: $0) } ?? []
        self.version = "1.0"
    }
}
```

Update `exportToJSON`:
```swift
func exportToJSON() -> String? {
    let exportData = ExportData(levels: levels, triggers: triggers)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    if let jsonData = try? encoder.encode(exportData),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        return jsonString
    }
    return nil
}
```

Update `importFromJSON`:
```swift
func importFromJSON(_ jsonString: String) -> Bool {
    guard let jsonData = jsonString.data(using: .utf8),
          let importedData = try? JSONDecoder().decode(ExportData.self, from: jsonData) else {
        return false
    }
    levels = importedData.levels
    triggers = importedData.triggers
    if let encodedStyles = try? JSONEncoder().encode(importedData.nodeStyles) {
        UserDefaults.standard.set(encodedStyles, forKey: nodeStylesKey)
    }
    saveContent()
    return true
}
```

Update `mergeFromJSON`:
```swift
func mergeFromJSON(_ jsonString: String) -> Bool {
    guard let jsonData = jsonString.data(using: .utf8),
          let importedData = try? JSONDecoder().decode(ExportData.self, from: jsonData) else {
        return false
    }
    let existingLevelIds = Set(levels.map { $0.id })
    let newLevels = importedData.levels.filter { !existingLevelIds.contains($0.id) }
    levels.append(contentsOf: newLevels)

    let existingTriggerIds = Set(triggers.map { $0.id })
    let newTriggers = importedData.triggers.filter { !existingTriggerIds.contains($0.id) }
    triggers.append(contentsOf: newTriggers)

    let currentStyles = loadNodeStyles()
    let existingRoomNumbers = Set(currentStyles.map { $0.roomNumber })
    let newStyles = importedData.nodeStyles.filter { !existingRoomNumbers.contains($0.roomNumber) }
    if let encodedStyles = try? JSONEncoder().encode(currentStyles + newStyles) {
        UserDefaults.standard.set(encodedStyles, forKey: nodeStylesKey)
    }
    saveContent()
    return true
}
```

- [ ] **Step 5: Delete dead files**

```bash
rm LevelGenerator/Models/ContentSection.swift
rm LevelGenerator/Views/Sheets/NewScriptSheet.swift
rm LevelGenerator/Parsers/LDtkScriptNameExtractor.swift
rm LevelGeneratorTests/LDtkScriptNameExtractorTests.swift
```

The project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16 automatic file sync), so deleting files from disk is sufficient — no `project.pbxproj` edits needed.

- [ ] **Step 6: Build for both platforms**

```bash
xcodebuild build -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -5
xcodebuild build -scheme LevelGenerator -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED` for both. If there are compile errors, trace them back to the removed symbols and fix.

- [ ] **Step 7: Run all tests**

```bash
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS' 2>&1 | tail -15
```

Expected: All tests pass (ScriptLuaGeneratorTests × 5, ContentStoreTriggerTests × 7, UI tests).

- [ ] **Step 8: Final commit**

```bash
git add -A
git commit -m "feat: remove dead code — old scripts, LDtk, ContentSection cleanup"
```

---

## Validation Checklist

Manual smoke test after all tasks:

- [ ] macOS: sidebar shows "Levels" + "Triggers" section
- [ ] Create a trigger "lamp" — appears in sidebar
- [ ] Select "lamp" — content column shows empty script list with "+ Add Script" toolbar button
- [ ] Create scripts "big" and "tiny" — appear in content column with `[Lua]` and `[Strings]` buttons
- [ ] `[Lua]` copies correct Lua block for that script
- [ ] `[Strings]` copies correct localization strings for that script
- [ ] Select "big" — ScriptView opens in detail with only Lua/Strings outputs and Save button (no Condicionales button, no conditional block)
- [ ] Add a dialog to "big", Save — dialog count updates in content column row
- [ ] Toolbar: "Condicionales (0)" button — opens `ConditionalScriptsEditorView` sheet
- [ ] In sheet, add a condition — script name picker shows "big" and "tiny" in Menu
- [ ] Select "tiny", close sheet — count updates to "Condicionales (1)"
- [ ] Save script, relaunch app — trigger, scripts, and conditionals persist
- [ ] iOS: Triggers tab shows trigger list; tap trigger → TriggerScriptsView; copy buttons work; Cond. button opens sheet
