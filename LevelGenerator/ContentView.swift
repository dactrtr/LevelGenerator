//
//  ContentView.swift
//  LevelGenerator
//
//  Created by Dactrtr on 2024/12/28.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedSection: AppSection = .contentManager
    
    var body: some View {
        NavigationStack {
            ContentManagerView()
        }
    }
}

#Preview {
    ContentView()
}
