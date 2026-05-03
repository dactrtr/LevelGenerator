# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**LevelGenerator** is a SwiftUI-based cross-platform (iOS + macOS) level design and script authoring tool. It lets designers create game levels with placeable items, configure room navigation, author dialog scripts with conditional logic, and export everything as JSON or Lua for integration with a game engine.

## Build & Test Commands

```bash
# Build for macOS
xcodebuild -scheme LevelGenerator -destination 'platform=macOS'

# Build for iOS Simulator
xcodebuild -scheme LevelGenerator -destination 'platform=iOS Simulator,name=iPhone 16'

# Run unit tests
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS'
```

Open `LevelGenerator.xcodeproj` in Xcode to build and run interactively (Cmd+R). The app forces light color scheme on launch.

No linting tools are configured.

## Architecture

### Data Layer (`Models/`)

**`SavedContent.swift`** is the core file — it contains all models and the `ContentStore` observable object.

- **`SavedLevel`** — a single room with doors (4 directions), placed items, tile set, lighting, and comic flags
- **`PlacedItem`** — an item on the map; types are `.prop`, `.enemy`, `.trigger`, `.item`; carries position, script references, and trigger metadata
- **`SavedScript`** — dialog sequences (image + text + key triples) plus a `conditionalScripts` list; generates Lua table output
- **`ConditionalScript`** — a game-state condition (variable + operator + value) linked to a target script; generates `condition:scriptName!` format strings
- **`PlayerVariable`** — 15 predefined game-state variables (inventory, skills, stats) with Spanish display labels
- **`ContentStore`** — `@ObservedObject` that owns all levels and scripts, persists to `UserDefaults`, and handles JSON export/import

**`PlacedItem.swift`** — model for individual map items, defined separately from `SavedContent.swift`.

### View Layer (`Views/`)

**Platform dispatch:** `ContentManagerView` reads the platform and renders either `MacContentView` (3-pane `NavigationSplitView`) or `iOSContentView` (`NavigationStack`).

**`LevelEditorView`** — main room editor. Left panel: mode picker + AddXxxView panels. Center: `MapView` (400×240 canvas) + `RoomInfoView` (door config). Right: scrollable `ListViews` per item type. Implements `LevelEditorState` protocol for read-only state binding into child views.

**`ScriptView`** — 3-pane script editor. Left: generated Lua and localization outputs with copy buttons. Center: toggle between dialog table and `ConditionalScriptsEditorView`. Right: input form for the selected dialog or condition.

**`ConditionalScriptsEditorView`** — row-based UI for conditional logic. Each `ConditionalScriptRowView` picks a `PlayerVariable`, an operator, a value, a target script, and a terminal flag. Warns if the target script doesn't exist.

**`RoomConnectionMapView`** — node graph of all rooms. Rooms render as colored draggable nodes; doors between rooms draw Bézier curves. Node positions and border colors are persisted separately in `ContentStore`.

**`MapView`** — canvas that renders the room background image with colored badge overlays for each `PlacedItem` (teal = prop, red = enemy, purple = item/trigger), preview ghosts, and door indicators.

### State & Data Flow

- `ContentStore` is injected as `@ObservedObject` from the root and passed down via `@Binding` or direct reference.
- Use `ContentStore.levelBinding(id:)` to get stable bindings by UUID (avoids index-based binding instability).
- Changes flow: view edits @Binding → calls `ContentStore.updateLevel()` / `updateScript()` → persists to UserDefaults → @Published triggers rerender.
- `SavedScript` decoder handles missing `conditionalScripts` field for backward compatibility with older saved data.

### Key Conventions

- English code, Spanish UI labels (e.g., `"Negar"`, `"Script destino"`, `"Terminal"`).
- Script names use lowercase-kebab-case (e.g., `"levelname-01"`).
- Trigger types: `"cutscene"`, `"search"`, `"call"`, `"counter"`, `"Story"`.
- `ConditionalScript` output format: `condition:scriptName!` (terminal) or `condition:scriptName`.
- Lua output is generated in `SavedScript` methods, not in views.
- No networking, Core Data, or third-party dependencies — only standard Apple frameworks.
