import Testing
import Foundation
import SwiftUI
@testable import LevelGenerator

struct ContentStoreTriggerTests {

    // Helper: fresh store with an isolated UserDefaults suite
    private func freshStore() -> ContentStore {
        let suiteName = "test-\(UUID().uuidString)"
        return ContentStore(defaults: UserDefaults(suiteName: suiteName)!)
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
