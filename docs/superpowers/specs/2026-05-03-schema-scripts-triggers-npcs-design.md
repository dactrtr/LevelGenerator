# Schema: Scripts, Triggers y NPCs — Diseño

**Fecha:** 2026-05-03  
**Estado:** Aprobado

---

## Contexto

LevelGenerator necesita refactorizarse para seguir el schema del juego donde Scripts son entidades globales y Triggers/NPCs los referencian por nombre. El modelo actual embebe scripts dentro de cada Trigger, lo que impide reutilización y no refleja la arquitectura real del juego.

Se parte de modelos limpios (sin migración de datos existentes).

---

## Arquitectura: Enfoque C — Tres modelos top-level independientes

### Modelos de datos (`SavedContent.swift`)

**`SavedScript`** — pool global de scripts

```swift
struct SavedScript: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var dialogs: [SavedDialog]

    struct SavedDialog: Codable, Hashable {
        var video: String    // estado del portrait (player, radioHand, etc.)
        var text: String     // texto visible
        var key: String      // clave de localización (en.strings)
        var screen: String?  // imagen estática opcional sobre el dialog box
    }
}
```

Estados válidos de `video`: `player`, `playerWorry`, `playerSurprise`, `playerHappy`, `playerAngry`, `playerSleepy`, `playerScared`, `playerCry`, `radioHand`, `radioPocket`, `radioRing`, `notesHand`.

**`SavedTrigger`** — reestructurado, sin scripts embebidos

```swift
struct SavedTrigger: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var triggerType: String?        // "Story"|"Cutscene"|"Search"|"Call"|"Counter"|nil
    var fallbackScript: String?     // nombre del script a usar si conditionalScripts falla
    var conditionalScripts: [ConditionalScript]
}
```

**`SavedNPC`** — nuevo modelo

```swift
struct SavedNPC: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var conditionalScripts: [ConditionalScript]
}
```

**`ConditionalScript`** — sin cambios. El picker de `scriptName` en el editor pasa a leer `ContentStore.scripts.map { $0.name }`.

**`ContentStore`** — nuevas colecciones top-level

```swift
@Published var scripts: [SavedScript] = []
@Published var triggers: [SavedTrigger] = []
@Published var npcs: [SavedNPC] = []
// levels: sin cambios
```

`ExportData` incluye `scripts`, `triggers`, `npcs`, `levels`, `nodeStyles`.

---

## Navegación y UI

### Sidebar (macOS `MacContentView` / iOS `iOSContentView`)

```
├── Levels          — igual que ahora
├── Scripts         — pool global, lista plana, botón + para crear
├── Triggers        — lista plana, botón + para crear
└── NPCs            — lista plana, botón + para crear
```

`SidebarItem` enum gana dos casos nuevos: `.script(UUID)` y `.npc(UUID)`.

### Detail column por selección

**Script seleccionado** → `ScriptView` (existente, adaptado):
- Campo `video` renombrado desde `image`
- Campo `screen` opcional agregado en el formulario de entrada

**Trigger seleccionado** → `TriggerDetailView` (nuevo):
- Nombre editable
- Picker `triggerType` (Story / Cutscene / Search / Call / Counter / nil)
- Picker/field `fallbackScript` — lista del pool global de scripts
- Botón "Condicionales (N)" → abre `ConditionalScriptsEditorView`
- Bloque Lua generado con botón de copia

**NPC seleccionado** → `NPCDetailView` (nuevo):
- Nombre editable
- Botón "Condicionales (N)" → abre `ConditionalScriptsEditorView`
- Bloque Lua generado con botón de copia

### `ConditionalScriptsEditorView`
Sin cambios estructurales. `availableScriptNames` se pasa desde `ContentStore.scripts.map { $0.name }`.

### Sheets de creación
- **Nuevo Script**: campo nombre → crea `SavedScript` vacío
- **Nuevo Trigger**: campo nombre → crea `SavedTrigger`
- **Nuevo NPC**: campo nombre → crea `SavedNPC`

---

## Generación de output (`ScriptLuaGenerator`)

Tres métodos estáticos:

```swift
// Script — usa dialog.video (era dialog.image)
static func lua(for script: SavedScript) -> String

// Trigger — genera bloque con type, fallback y conditionalScripts
static func lua(for trigger: SavedTrigger) -> String

// Localización — sin cambios
static func localization(for script: SavedScript) -> String
```

**Output Lua de un Trigger:**
```lua
{
    iid = "550e8400-e29b-41d4-a716-446655440000",
    type = "Search",
    script = "script-fallback",
    conditionalScripts = {
        "items.hasLamp:script-con-lampara!",
        "true:script-fallback"
    }
},
```

El `iid` se genera desde `trigger.id.uuidString`.

**Output Lua de un NPC:**
```lua
{
    iid = "550e8400-e29b-41d4-a716-446655440001",
    conditionalScripts = {
        "true:dialogo-inicial"
    }
},
```

---

## Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `Models/SavedContent.swift` | Nuevos modelos `SavedNPC`, reestructura `SavedTrigger`, nuevas colecciones en `ContentStore`, nuevo `ExportData` |
| `Models/ScriptLuaGenerator.swift` | Renombrar `image` → `video`, agregar `lua(for trigger:)` |
| `Models/SidebarItem.swift` | Agregar casos `.script(UUID)` y `.npc(UUID)` |
| `Views/macOS/MacContentView.swift` | Sidebar con 4 secciones, detail column para Script/Trigger/NPC |
| `Views/iOS/iOSContentView.swift` | Mismo ajuste para iOS |
| `Views/ScriptView.swift` | `image` → `video`, campo `screen` opcional |
| `Views/ConditionalScriptsEditorView.swift` | `availableScriptNames` desde pool global |
| `Views/TriggerDetailView.swift` | Nuevo archivo |
| `Views/NPCDetailView.swift` | Nuevo archivo |
| `Views/Sheets/NewNPCSheet.swift` | Nuevo archivo |

---

## Decisiones explícitas

- **Sin migración**: los datos existentes en `UserDefaults` se descartan. Los nuevos modelos parten limpios.
- **`iid` de Triggers y NPCs**: se deriva de `id.uuidString`, no se guarda un campo separado.
- **Grants en NPC**: fuera de scope por ahora. `ConditionalScript` sin cambios.
- **`screen` en `SavedDialog`**: campo opcional; el editor lo muestra como un `TextField` vacío por defecto.
- **NPCs en el mapa**: fuera de scope. NPCs son solo grupos lógicos con nombre + condicionales.
