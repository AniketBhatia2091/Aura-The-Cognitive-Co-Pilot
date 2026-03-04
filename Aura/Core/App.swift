// AuraApp.swift

import SwiftUI

@main
struct AuraApp: App {
    
    // Shared state managers initialized at the App level
    @State private var inputLogic = InputLogic()
    @State private var uiState = UIState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(inputLogic)
                .environment(uiState)
                .background(Color.clear)
        }
        .modelContainer(for: [
            AuraProject.self,
            BrainDumpSession.self,
            AuraTask.self
        ])
    }
}
