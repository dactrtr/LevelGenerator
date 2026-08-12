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
