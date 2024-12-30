#if os(iOS)
import SwiftUI

struct iOSContentView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSection: ContentSection
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingNewScriptSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var importText: String
    @Binding var showingImportAlert: Bool
    @Binding var importAlertMessage: String
    
    var body: some View {
        NavigationStack {
            ContentListView(
                contentStore: contentStore,
                selectedSection: $selectedSection,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingNewScriptSheet: $showingNewScriptSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet,
                selectedLevel: .constant(nil),
                selectedScript: .constant(nil)
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
    }
}
#endif 