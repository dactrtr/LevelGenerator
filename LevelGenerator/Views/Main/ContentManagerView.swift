import SwiftUI

struct ContentManagerView: View {
    @StateObject private var contentStore = ContentStore()
    @State private var selectedSection: ContentSection = .levels
    @State private var showingNewLevelSheet = false
    @State private var showingNewScriptSheet = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var importText = ""
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""
    @State private var showingConnectionMap = false
    
    var body: some View {
        Group {
            #if os(iOS)
            iOSContentView(
                contentStore: contentStore,
                selectedSection: $selectedSection,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingNewScriptSheet: $showingNewScriptSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet,
                importText: $importText,
                showingImportAlert: $showingImportAlert,
                importAlertMessage: $importAlertMessage
            )
            .toolbar {
                if selectedSection == .levels {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingConnectionMap = true
                        } label: {
                            Label("View Connections", systemImage: "map")
                        }
                    }
                }
            }
            #else
            MacContentView(
                contentStore: contentStore,
                selectedSection: $selectedSection,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingNewScriptSheet: $showingNewScriptSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet,
                importText: $importText,
                showingImportAlert: $showingImportAlert,
                importAlertMessage: $importAlertMessage
            )
            .toolbar {
                if selectedSection == .levels {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showingConnectionMap = true
                        } label: {
                            Label("View Connections", systemImage: "map")
                        }
                    }
                }
            }
            #endif
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingConnectionMap) {
            NavigationStack {
                RoomConnectionMapView(levels: contentStore.levels, contentStore: contentStore)
                    .navigationTitle("Room Connections")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingConnectionMap = false
                            }
                        }
                    }
            }
        }
    }
} 