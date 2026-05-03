import Testing
import Foundation
import SwiftUI
@testable import LevelGenerator

struct ContentStoreTests {

    private func freshStore() -> ContentStore {
        let suiteName = "test-\(UUID().uuidString)"
        return ContentStore(defaults: UserDefaults(suiteName: suiteName)!)
    }

    // MARK: Scripts

    @Test func addScript_appendsScript() {
        let store = freshStore()
        store.addScript(SavedScript(name: "hello"))
        #expect(store.scripts.count == 1)
        #expect(store.scripts[0].name == "hello")
    }

    @Test func deleteScript_removesScript() {
        let store = freshStore()
        store.addScript(SavedScript(name: "hello"))
        store.deleteScript(at: IndexSet([0]))
        #expect(store.scripts.isEmpty)
    }

    @Test func scriptBinding_returnsCorrectScript() {
        let store = freshStore()
        store.addScript(SavedScript(name: "hello"))
        let id = store.scripts[0].id
        let binding = store.scriptBinding(id: id)
        #expect(binding.wrappedValue.name == "hello")
    }

    // MARK: Triggers

    @Test func addTrigger_appendsTrigger() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp"))
        #expect(store.triggers.count == 1)
        #expect(store.triggers[0].name == "lamp")
    }

    @Test func addTrigger_withTypeAndFallback_storesFields() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp", triggerType: "Search", fallbackScript: "lamp-dialog"))
        #expect(store.triggers[0].triggerType == "Search")
        #expect(store.triggers[0].fallbackScript == "lamp-dialog")
    }

    @Test func deleteTrigger_removesTrigger() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp"))
        store.deleteTrigger(at: IndexSet([0]))
        #expect(store.triggers.isEmpty)
    }

    @Test func triggerBinding_returnsCorrectTrigger() {
        let store = freshStore()
        store.addTrigger(SavedTrigger(name: "lamp"))
        let id = store.triggers[0].id
        let binding = store.triggerBinding(id: id)
        #expect(binding.wrappedValue.name == "lamp")
    }

    // MARK: NPCs

    @Test func addNPC_appendsNPC() {
        let store = freshStore()
        store.addNPC(SavedNPC(name: "cat"))
        #expect(store.npcs.count == 1)
        #expect(store.npcs[0].name == "cat")
    }

    @Test func deleteNPC_removesNPC() {
        let store = freshStore()
        store.addNPC(SavedNPC(name: "cat"))
        store.deleteNPC(at: IndexSet([0]))
        #expect(store.npcs.isEmpty)
    }

    @Test func npcBinding_returnsCorrectNPC() {
        let store = freshStore()
        store.addNPC(SavedNPC(name: "cat"))
        let id = store.npcs[0].id
        let binding = store.npcBinding(id: id)
        #expect(binding.wrappedValue.name == "cat")
    }

    // MARK: Export / Import round-trip

    @Test func exportImportRoundTrip_preservesAllEntities() {
        let store = freshStore()
        store.addScript(SavedScript(name: "hello"))
        store.addTrigger(SavedTrigger(name: "lamp", triggerType: "Search"))
        store.addNPC(SavedNPC(name: "cat"))

        guard let json = store.exportToJSON() else {
            Issue.record("exportToJSON returned nil")
            return
        }

        let store2 = freshStore()
        let success = store2.importFromJSON(json)
        #expect(success)
        #expect(store2.scripts.count == 1)
        #expect(store2.triggers.count == 1)
        #expect(store2.npcs.count == 1)
        #expect(store2.scripts[0].name == "hello")
        #expect(store2.triggers[0].triggerType == "Search")
        #expect(store2.npcs[0].name == "cat")
    }
}
