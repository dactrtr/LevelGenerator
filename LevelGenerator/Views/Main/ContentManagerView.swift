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
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            ContentListView(
                contentStore: contentStore,
                selectedSection: $selectedSection,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingNewScriptSheet: $showingNewScriptSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet
            )
        }
        .sheet(isPresented: $showingNewLevelSheet) {
            NavigationStack {
                NewLevelSheet(contentStore: contentStore)
            }
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NavigationStack {
                NewScriptSheet(contentStore: contentStore)
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(contentStore: contentStore, isPresented: $showingExportSheet)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView(
                contentStore: contentStore,
                isPresented: $showingImportSheet,
                importText: $importText,
                showingAlert: $showingImportAlert,
                alertMessage: $importAlertMessage
            )
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
        #endif
    }
} 