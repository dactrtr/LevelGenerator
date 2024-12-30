import SwiftUI

extension View {
    func safeToolbar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(macOS)
        self.toolbar {
            ToolbarItemGroup {
                content()
            }
        }
        #else
        self.toolbar {
            content()
        }
        #endif
    }
} 