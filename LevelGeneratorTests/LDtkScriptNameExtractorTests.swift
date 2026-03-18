import Testing
import Foundation
@testable import LevelGenerator

struct LDtkScriptNameExtractorTests {

    // MARK: - Room format (data.json)

    @Test func roomFormat_extractsScriptField() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "giftFor100", "conditionalScripts": [] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names == ["giftFor100"])
    }

    @Test func roomFormat_extractsConditionalScriptNames() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "fallback", "conditionalScripts": ["isTiny:hugeXmas", "!isTiny:normalXmas!"] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names.contains("fallback"))
        #expect(names.contains("hugeXmas"))
        #expect(names.contains("normalXmas"))
        #expect(names.count == 3)
    }

    @Test func roomFormat_deduplicates() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "same", "conditionalScripts": ["x:same"] } },
              { "customFields": { "script": "same", "conditionalScripts": [] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names == ["same"])
    }

    @Test func roomFormat_sortedAlphabetically() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "zScript", "conditionalScripts": ["x:aScript"] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names == ["aScript", "zScript"])
    }

    @Test func roomFormat_dropsEmptyConditionalScriptName() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": "ok", "conditionalScripts": ["isTiny:!", "x:valid"] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(!names.contains(""))
        #expect(names.contains("valid"))
        #expect(names.contains("ok"))
    }

    @Test func roomFormat_noTriggersKey_returnsEmpty() throws {
        let json = #"{ "entities": {} }"#
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names.isEmpty)
    }

    @Test func roomFormat_nullScriptField_ignored() throws {
        let json = """
        {
          "entities": {
            "Triggers": [
              { "customFields": { "script": null, "conditionalScripts": [] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names.isEmpty)
    }

    // MARK: - LDtk project format

    @Test func ldtkFormat_extractsScriptNames() throws {
        let json = """
        {
          "levels": [{
            "layerInstances": [{
              "entityInstances": [{
                "__identifier": "Triggers",
                "fieldInstances": [
                  { "__identifier": "script", "__value": "introDialog" },
                  { "__identifier": "conditionalScripts", "__value": ["battery<20:lowPower"] }
                ]
              }]
            }]
          }]
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names.contains("introDialog"))
        #expect(names.contains("lowPower"))
    }

    @Test func ldtkFormat_fallsBackToRoomFormat_whenNoTriggerEntities() throws {
        let json = """
        {
          "levels": [{
            "layerInstances": [{
              "entityInstances": [{
                "__identifier": "Items",
                "fieldInstances": []
              }]
            }]
          }],
          "entities": {
            "Triggers": [
              { "customFields": { "script": "roomScript", "conditionalScripts": [] } }
            ]
          }
        }
        """
        let names = try LDtkScriptNameExtractor().extract(from: Data(json.utf8))
        #expect(names == ["roomScript"])
    }

    // MARK: - Error cases

    @Test func invalidJSON_throws() {
        let bad = Data("not json".utf8)
        #expect(throws: (any Error).self) {
            try LDtkScriptNameExtractor().extract(from: bad)
        }
    }

    @Test func emptyJSON_returnsEmpty() throws {
        let names = try LDtkScriptNameExtractor().extract(from: Data("{}".utf8))
        #expect(names.isEmpty)
    }
}
