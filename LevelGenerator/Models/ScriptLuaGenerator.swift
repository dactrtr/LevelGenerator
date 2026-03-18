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
