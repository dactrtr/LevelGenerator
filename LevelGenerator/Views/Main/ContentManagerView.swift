import SwiftUI

struct ContentManagerView: View {
    @StateObject private var contentStore = ContentStore()
    @State private var selectedSidebarItem: SidebarItem = .levels
    @State private var showingNewLevelSheet = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var importText = ""
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""

    var body: some View {
        NavigationStack {
            #if os(iOS)
            iOSContentView(
                contentStore: contentStore,
                selectedSidebarItem: $selectedSidebarItem,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet,
                importText: $importText,
                showingImportAlert: $showingImportAlert,
                importAlertMessage: $importAlertMessage
            )
            .toolbar {
                if case .levels = selectedSidebarItem {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink {
                            RoomConnectionMapView(levels: contentStore.levels, contentStore: contentStore)
                                .navigationTitle("Room Connections")
                        } label: {
                            Label("View Connections", systemImage: "map")
                        }
                    }
                }
            }
            #else
            MacContentView(
                contentStore: contentStore,
                selectedSidebarItem: $selectedSidebarItem,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet,
                importText: $importText,
                showingImportAlert: $showingImportAlert,
                importAlertMessage: $importAlertMessage
            )
            .toolbar {
                if case .levels = selectedSidebarItem {
                    ToolbarItem(placement: .automatic) {
                        NavigationLink {
                            RoomConnectionMapView(levels: contentStore.levels, contentStore: contentStore)
                                .navigationTitle("Room Connections")
                        } label: {
                            Label("View Connections", systemImage: "map")
                        }
                    }
                }
            }
            #endif
        }
        .preferredColorScheme(.light)
    }
}
