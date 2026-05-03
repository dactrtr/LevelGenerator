import Testing
import Foundation
@testable import LevelGenerator

struct ScriptLuaGeneratorTests {

    @Test func lua_containsNameAndDialogKey() {
        let script = SavedScript(name: "big", dialogs: [
            SavedScript.SavedDialog(video: "player", text: "Hello", key: "big-01")
        ])
        let result = ScriptLuaGenerator.lua(for: script)
        #expect(result.contains("name = \"big\""))
        #expect(result.contains("text = \"big-01\""))
        #expect(result.contains("video = 'player'"))
    }

    @Test func lua_emptyDialogs_stillContainsName() {
        let script = SavedScript(name: "empty")
        let result = ScriptLuaGenerator.lua(for: script)
        #expect(result.contains("name = \"empty\""))
    }

    @Test func localization_formatsKeyValuePair() {
        let script = SavedScript(name: "big", dialogs: [
            SavedScript.SavedDialog(video: "player", text: "Hello world", key: "big-01")
        ])
        let result = ScriptLuaGenerator.localization(for: script)
        #expect(result == "\"big-01\" = \"Hello world\"")
    }

    @Test func localization_multipleDialogs_joinedWithDoubleNewline() {
        let script = SavedScript(name: "big", dialogs: [
            SavedScript.SavedDialog(video: "player", text: "Line 1", key: "big-01"),
            SavedScript.SavedDialog(video: "player", text: "Line 2", key: "big-02")
        ])
        let result = ScriptLuaGenerator.localization(for: script)
        #expect(result.contains("\"big-01\" = \"Line 1\""))
        #expect(result.contains("\"big-02\" = \"Line 2\""))
        #expect(result.contains("\n\n"))
    }

    @Test func localization_emptyDialogs_returnsEmptyString() {
        let script = SavedScript(name: "empty")
        let result = ScriptLuaGenerator.localization(for: script)
        #expect(result.isEmpty)
    }

    @Test func triggerLua_containsIidAndType() {
        let trigger = SavedTrigger(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                                    name: "lamp-trigger",
                                    triggerType: "Search",
                                    fallbackScript: "lamp-dialog")
        let result = ScriptLuaGenerator.lua(for: trigger)
        #expect(result.contains("iid = \"00000000-0000-0000-0000-000000000001\""))
        #expect(result.contains("type = \"Search\""))
        #expect(result.contains("script = \"lamp-dialog\""))
    }

    @Test func triggerLua_nilType_omitsTypeField() {
        let trigger = SavedTrigger(id: UUID(), name: "t", triggerType: nil, fallbackScript: nil)
        let result = ScriptLuaGenerator.lua(for: trigger)
        #expect(!result.contains("type ="))
        #expect(!result.contains("script ="))
    }

    @Test func triggerLua_withConditionals_includesConditionStrings() {
        var condition = ConditionalScript(variablePath: "isTiny", variableType: "bool")
        condition.scriptName = "tiny-dialog"
        condition.isTerminal = true
        let trigger = SavedTrigger(id: UUID(), name: "t", conditionalScripts: [condition])
        let result = ScriptLuaGenerator.lua(for: trigger)
        #expect(result.contains("\"isTiny:tiny-dialog!\""))
    }

    @Test func npcLua_containsIidAndConditionals() {
        var condition = ConditionalScript(variablePath: "true", variableType: "bool")
        condition.scriptName = "hello"
        let npc = SavedNPC(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                            name: "cat",
                            conditionalScripts: [condition])
        let result = ScriptLuaGenerator.lua(for: npc)
        #expect(result.contains("iid = \"00000000-0000-0000-0000-000000000002\""))
        #expect(result.contains("\"true:hello\""))
    }
}
