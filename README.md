# LevelGenerator

A SwiftUI-based cross-platform (iOS + macOS) level design and script authoring tool for **DinoPirates**, a Playdate game. It lets designers create game levels with placeable items, configure room navigation, author dialog scripts with conditional logic, and export everything as JSON or Lua for integration with the game engine.

## Features

- Room/level editor with a visual map canvas for placing props, enemies, items, and triggers
- Door-based room navigation with a node-graph view of how rooms connect
- Dialog script authoring (image + text + key sequences) with conditional branching based on game-state variables
- Lua and JSON export for consumption by the game engine
- Native iOS and macOS support via a shared SwiftUI codebase

## Build & Test

```bash
# Build for macOS
xcodebuild -scheme LevelGenerator -destination 'platform=macOS'

# Build for iOS Simulator
xcodebuild -scheme LevelGenerator -destination 'platform=iOS Simulator,name=iPhone 16'

# Run unit tests
xcodebuild test -scheme LevelGenerator -destination 'platform=macOS'
```

Open `LevelGenerator.xcodeproj` in Xcode to build and run interactively (Cmd+R).

## Architecture

See [`CLAUDE.md`](./CLAUDE.md) for a detailed breakdown of the data layer, view layer, and state management conventions used in this project.

## Project Status

This project is **not under active development**. It became easier to shift the way the game builds its levels to use **LDtk** instead of continuing to invest time into building out this custom tool.
