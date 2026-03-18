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
