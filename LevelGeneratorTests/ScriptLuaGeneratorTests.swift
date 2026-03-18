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
